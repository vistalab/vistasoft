function hdr = ReadPfileHeader(PfileName)
% header = ReadPfileHeader(PfileName) Returns header info from Pfile
%

% 99.02.15 RFD wrote it, based on /grey/u2/mri/recon/shift_sources/dumpheader.c
% (and it's associated header files).
%
% DBR 3/99 Changed frameRate field name to framePeriod (might as
% well get it right...)

% 3T or 1.5T?
threeTFlag = (PfileName(end-1)=='.' & PfileName(end)=='7');

% OPEN FILE
fp = fopen(PfileName, 'r', 'b');	% open in read, big-endian mode
if fp < 1
   disp(['readPfileHeader: Can not open ' PfileName '.']);
   hdr = [];
   return;
end

if ~threeTFlag
  %rdbHeaderBytes = 39940;	% total num bytes of the header
  rdbImageDataOffset = 38916; 	% offset to get to image data section
  sliceThicknessOffset = 26;
  sliceSpacingOffset = 78;
  TRoffset = 74;
  psdOffset = 102;
else
  %rdbHeaderBytes = 39984;	% total num bytes of the header
  rdbImageDataOffset = 38940; 	% offset to get to image data section
  sliceThicknessOffset = 28;
  sliceSpacingOffset = 78;	% Either 78 or 80 - must check with nonzero slice spacing
  TRoffset = 78;		% Must be 78 if above is 78, 76 if above is 80
  psdOffset = 108;
end  

% READ STUFF FROM RDB SECTION
fread(fp, 16, 'uchar');
hdr.date = fread(fp, 10, 'char')';	% offset = 16
ii = find(hdr.date == 0);
hdr.date = char(hdr.date(1:ii-1));
hdr.time = fread(fp, 8, 'char')';	% offset = 26
ii = find(hdr.time == 0);
hdr.time = char(hdr.time(1:ii-1));
fread(fp, 34, 'uchar');
hdr.nSlices = fread(fp, 1, 'int16');	% offset = 68
hdr.necho = fread(fp, 1, 'int16');	% offset = 70
hdr.nAvs=fread(fp, 1, 'int16');	% offset = 72
hdr.totalShots=fread(fp, 1, 'int16');	% offset = 74
% skip baselineViews and hnOver
baselineViews=fread(fp, 1, 'int16');	% offset = 76
hnOver=fread(fp, 1, 'int16');	% offset = 78
hdr.frameSize=fread(fp,1, 'int16');	% offset = 80
fread(fp, 28, 'uchar');
hdr.fullSize = fread(fp, 1, 'int16');	% offset = 110
fread(fp, 104, 'uchar');
user0 = fread(fp, 1, 'float32');	                  % (user0) offset = 282
hdr.totalFrames = fread(fp, 1, 'float32');	% (user1) offset = 286

user2 = fread(fp,1,'float32');                         % (user2) offset = 290       
hdr.freqEncodeMatSize = fread(fp,1,'float32'); % (user3) offset = 294
%fread(fp, , 'uchar');
hdr.numInterleaves = fread(fp, 1, 'float32'); % (user4) offset = 298
% skip grev and trajFileName
grev = fread(fp, 1, 'float32');	% (user5) offset = 302
%hdr.trajFileName = sprintf('sg%d_%d_%d.kk', hdr.grev, hdr.numInterleaves, user0);

% READ STUFF FROM IMAGE DATA SECTION
frewind(fp);
fread(fp, rdbImageDataOffset+sliceThicknessOffset, 'uchar');
hdr.sliceThickness = fread(fp, 1, 'float32');	% offset = rdbImageDataOffset+26
fread(fp, 4, 'uchar');
hdr.FOV = fread(fp, 1, 'float32'); % offset = rdbImageDataOffset+34
fread(fp, sliceSpacingOffset, 'uchar');
hdr.sliceSpacing = fread(fp, 1, 'float32');	 % offset = rdbImageDataOffset+116
fread(fp, TRoffset, 'uchar');
hdr.TR = fread(fp, 1, 'int32')/1000;	% offset = rdbImageDataOffset+194
fread(fp, 4, 'uchar');
hdr.TE = fread(fp, 1, 'int32')/1000;	% offset = rdbImageDataOffset+202
fread(fp, psdOffset, 'uchar');
hdr.psd = fread(fp, 33, 'char')';	% offset = rdbImageDataOffset+308
ii = find(hdr.psd == 0);
hdr.psd = char(hdr.psd(1:ii-1));

fclose(fp);

hdr.framePeriod = hdr.TR*hdr.numInterleaves/1000;	 %s per frame
