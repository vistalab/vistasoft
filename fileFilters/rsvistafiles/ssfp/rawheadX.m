
function [header,rhuser] = rawheadX(fname,displayinfo);
%function [header,rhuser] = rawheadX(fname,displayinfo);
%
%	Function returns header information from the given P-file.
%	the header information is primarily returned in the structure
%	header, although the rhuser variables are returned as an array
%	in rhuser.
%
%	INPUT:
%		fname   = path and file name.
%		displayinfo = 1 to display information as it is read.
%
%	B.Hargreaves -- April 2008.
%       minor mods 7/21/08  Tom Brosnan
%
%       now handles 12.X, 14.X, and 20.X Pfiles
%
%

if (nargin < 2) displayinfo=0; end;

% -- Check if file exists, and error if not.
if (~exist(fname))
	tt = sprintf('%s:  file not found.',fname);
	error(tt);
end;

%
%

% -- Open file.
fip = fopen(fname,'r','l'); 	
if fip == -1
  tt = sprintf('File %s not found\n',fn);
  error(tt);
end

header = struct('filename',fname);

%
% ===========================================================
% Extract Version.  It seems like 7 or less is before ESE 9.1
%  ver          Signa release name
%  ---          ------------------ 
%  5.0          5.X 
%  7.0          LX 
%  8.0          "New" LX 
%  9.0          EXCITE (11.0) 
%  11.0         12.0 
%  14.2         14.0 
%  14.3         14.0 M3 and above 
%  20.005       20.X 
%  20.006       20.X    (latest release as of 6/2008)

%
%	This determines the sizes of parts of the header, 
%	so it's nice to do something about it.
% ===========================================================
%
ver = fread(fip,1,'float');
%if (ver ~= 12) error('Only version 12 currently supported'); end;
if (ver < 11) error('Versions prior to 11 not supported'); end;
header = add2struct(header,'version',ver);


% -- Each parameter in the header has a name (that will be
% -- used in the structure) a bytes offset (depending on version)
% -- and a type.  This is an organized way of telling this program
% -- what to read:

fieldnames = {'run','npasses','frsize','nframes','nslices','nechoes','rawhdrsize'};
offsets = [4,64,80,74,68,70,1468];
types = {'uint32','uint16','uint16','uint16','uint16','uint16','uint32'};

% -- Just adding more fields to read.
fieldnames = {fieldnames{:},'ptsize','nex','startrcvr','endrcvr','rhimsize','rhrecon'};
offsets = [offsets,82,72,200,202,106,60];
types = {types{:},'uint16','uint16','uint16','uint16','uint16','uint16'};

%
% version-specific header values
%
if (ver >= 20) 
	% -- Even more fields to read.
	fieldnames = {fieldnames{:},'rawsize','exam','series','image'};
	offsets = [offsets,1660,148712,148724,148726];
	types = {types{:},'uint64','uint16','uint16','uint16'};

elseif (ver >= 14.3)
	% -- Even more fields to read.
	fieldnames = {fieldnames{:},'rawsize','exam','series','image'};
	offsets = [offsets,116,144884,144896,144898];
	types = {types{:},'uint32','uint16','uint16','uint16'};

elseif (ver >= 14.0)
%
% Note that Matlab reads 14.2 as 14.19999980926514, which is *not* greater than 14.2!
%
	% -- Even more fields to read.
	fieldnames = {fieldnames{:},'rawsize','exam','series','image'};
	offsets = [offsets,116,143384,143396,143398];
	types = {types{:},'uint32','uint16','uint16','uint16'};

else	%%% ver = 11.0
	% -- Even more fields to read.
	fieldnames = {fieldnames{:},'rawsize','exam','series','image'};
	offsets = [offsets,116,65200,65212,65214];
	types = {types{:},'uint32','uint16','uint16','uint16'};

end;


%
%
%
for k=1:length(fieldnames)
	header = readandadd(fip,header,offsets(k),fieldnames{k},types{k});
end;



% -- Number of coils is actually not explicitly stored, so
% -- we just add it manually because it is useful.

ncoils = header.endrcvr - header.startrcvr + 1;
header = add2struct(header,'ncoils',ncoils);


% -- Read rhuser variables.
% -- Note that these are not contiguously stored (0-19, then 20-39 are.)
fseek(fip,216,-1);
rh019 = fread(fip,20,'float');
fseek(fip,1000,-1);
rh2048 = fread(fip,29,'float');
rhuser = [rh019(:); rh2048(:)];


fclose(fip);

% -- Just dump out the full header information.
%
if (displayinfo == 1)
	header	
end;


return;


%------------------------------------------------------------
function newstruct = readandadd(fid,oldstruct,offset,pname,ptype)
%
%	Internal function to read a header variable, then
%	add it to the structure.  This may be a bit slow, but
%	is designed to be simple to program.
%
%	INPUT:
%		fid = file pointer.
%		oldstruct = structure we are adding to.
%		offset = byte offset of parameter.
%		pname = name of parameter to use in structure (arbitrary).
%		ptype = type (int32, etc)		

fseek(fid,offset,-1);
param = fread(fid,1,ptype);
newstruct = add2struct(oldstruct,pname,param);
return;


%------------------------------------------------------------
function newstruct = add2struct(oldstruct,newfield,newval)
%
%	Internal function to add a field to a structure.  
%
%	INPUT:
%		oldstruct = structure we are adding to.
%		newfield = name of new field to add.
%		newval = value of field.
%
svals = struct2cell(oldstruct);
sfields=fieldnames(oldstruct);

svals = {svals{:} newval};
sfields = {sfields{:} newfield};
newstruct = cell2struct(svals,sfields,2);



