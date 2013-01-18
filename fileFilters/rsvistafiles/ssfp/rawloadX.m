function [data,header] = rawloadX(fname,frames,echoes,slices,coils)
%function [data,header] = rawloadX(fname,frames,echoes,slices,coils);
%
%	Function reads selected (or all) data from a P-file,
%	using given lists of frames, echoes, slices and/or coils.  
%
%	INPUT:
%		fname   = path and file name.
%		frames  = frame numbers to read (Frame 0=baseline).
%		echoes  = echo numbers to read (0...).
%		slices  = slice numbers to read (0...).
%		coils   = coil numbers to read (0...).
%
%	OUTPUT:
%		data = data array (up to 5 dimensions, including all
%			specified frames, echoes, slices, coils.
%		header = header structure - see rawheadX.m
%
%	EXAMPLES:
%	  d = rawloadX('P00000.7');	% Read full p-file, no baselines.
%	  d = rawloadX('P00000.7',[],[],[],0);	% Read only 1st coil.
%	  d = rawloadX('P00000.7',[0:256]);	% Read all data with baselines
%	  d = rawloadX('P00000.7',[],[],[1,2,4,7]; % Read slices 1,2,4,7.
%
%	B.Hargreaves -- April 2008.
%

if (nargin < 2) frames=[]; end;
if (nargin < 3) echoes=[]; end;
if (nargin < 4) slices=[]; end;
if (nargin < 5) coils=[]; end;


% -- Read header information
header = rawheadX(fname);


% -- Open file.
fip = fopen(fname,'r','l'); 	
if fip == -1
  tt = sprintf('File %s not found\n',fn);
  error(tt);
end



% -- Check parameters passed are reasonable.
if (length(frames)==0) frames = [1:header.nframes]; end;
if (length(echoes)==0) echoes = [1:header.nechoes]; end;
if (length(slices)==0) slices = [1:header.nslices]; end;
if (length(coils)==0) coils = [1:header.ncoils]; end;

frames = checkrange(frames,0,header.nframes,'Frames');
echoes = checkrange(echoes,1,header.nechoes,'Echoes');
slices = checkrange(slices,1,header.nslices,'Slices');
coils = checkrange(coils,1,header.ncoils,'Coils');

% --- Allocate array for data, based on passed arguments
%	or defaults.
data = zeros(header.frsize,length(frames),length(echoes),length(slices),length(coils));

% --- Change all to start at 0, EXCEPT frames,
%	as the default is to ignore the baseline.
echoes = echoes-1;
slices = slices-1;
coils = coils-1;


ptsize = header.ptsize;			% Sample size (bytes)
framesize = 2*ptsize*header.frsize;	% Frame size in bytes.
echosize = framesize*header.nframes;	% Size of one echo (bytes)
slicesize = echosize*header.nechoes;	% Size of one slice (bytes)
coilsize = slicesize*header.nslices;	% Size of one echo (bytes)

%--display [framesize echosize slicesize coilsize]

rawhdrsize = header.rawhdrsize;
rawdatasize = header.rawsize;


%
% skip past the header (to the DISDAQ frame)
%
fseek(fip,rawhdrsize,-1);

%
%
% --- For each entity (coil, slice, echo, frame) we have variables
%	count and index.  Index indicates the next index into the
%	list for the entity (ie next coil is coils(coilindex).
%	count indicates the file position for that entity.
coilcount = 0;
coilindex = 1;		% Index into coils.
while (coilindex <= length(coils))
  coilskip = coils(coilindex)-coilcount;
  fseek(fip,coilskip*coilsize,0); % Skip to desired coil
  coilcount=coilcount+coilskip;	  % Coil position.

  sliceindex = 1;		% Index into slices
  slicecount = 0;
  while (sliceindex <= length(slices))
    sliceskip = slices(sliceindex)-slicecount;
    fseek(fip,sliceskip*slicesize,0); % Skip to desired slice;
    slicecount = slicecount+sliceskip;

    echoindex = 1;		% Index into echoes
    echocount = 0;
    while (echoindex <= length(echoes))
      echoskip = echoes(echoindex)-echocount;
      fseek(fip,echoskip*echosize,0); % Skip to desired echo
      echocount = echocount+echoskip;

      frameindex = 1;		% Index into frames
      framecount = 0;
      while (frameindex <= length(frames))
        frameskip = frames(frameindex)-framecount;
        fseek(fip,frameskip*framesize,0); % Skip to desired frame.
	framecount = framecount+frameskip;
	
	%DEBUG:tt = sprintf('Reading Frame %d, Echo %d, Slice %d, Coil %d',frames(frameindex),echoes(echoindex),slices(sliceindex),coils(coilindex)); disp(tt);

	  % Read frame
	dattypes = {'int16','int32'};
	dr = fread(fip,framesize/ptsize,dattypes{ptsize/2});
	dr = reshape(dr,2,framesize/ptsize/2);  % -- Shape to 2xN
	dr = dr(1,:)+i*dr(2,:);	  % -- Convert to complex.

	% -- Place in data array.	
	data(:,frameindex,echoindex,sliceindex,coilindex) = dr;

	framecount=framecount+1; frameindex=frameindex+1;
      end;  % --Frame loop.
      echocount=echocount+1; echoindex=echoindex+1;
    end;  % --Echo loop.
    slicecount=slicecount+1; sliceindex=sliceindex+1; 
  end;  % --Slice loop.
  coilcount=coilcount+1; coilindex=coilindex+1;
end;  % --Coil loop.


return;		% -- End of main function.



function arrout = checkrange(arr,amin,amax,atype)
%%%% -- Check values in array are within range, and remove ones that
	%%%are not!
f = find(arr >= amin);
arrout = arr(f);
f = find(arrout <= amax);
arrout = arrout(f);

if (length(arrout) < length(arr))
  arr = arr(:);
  f1 = find(arr < amin);
  f2 = find(arr > amax);
  tt = sprintf('%d %s out of range: ',length(f1)+length(f2),atype); disp(tt);
  disp([arr(f1); arr(f2)].');
end;
return;
%%%% --------



