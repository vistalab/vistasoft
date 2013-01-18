function hdr = analyzeWrite(imArray, fileName, mmPerVox, notes, origin)
%  hdr = analyzeWrite(imArray, fileName, [mmPerVox], [notes], [origin]);
%
% Saves Analyze7.5 image file from a matlab array 'imArray'. 
% fileName should be a root filename- no '.img' or '.hdr' suffix.
% mmPerVox is the row,col,slice voxel size, in mm. Defaults to 
% [1 1 1]. 
%
% If imarray is int16 or int32 then it will be saved as such. If it is
% logical it will be saved as uint1 (1-bit). Any other matlab type will
% be saved as 'float'.
%
% Returns hdr - Analyse header modified after image write.
%
% REQUIRES:
%   fmris_write_analyze from VISTASOFT 'filters' module. 
%
% SEE ALSO: loadAnalyze, analyze2mrGray, mrGray2Analyze
%
% HISTORY:
%   2002.04.01 RFD (bob@white.stanford.edu) wrote it.
%   2003.07.09 RFD added origin option.
%   2003.12.04 RFD: minor edits to allow for 4-d data.
%   2004.01.06 RFD: replaced 'V = spm_vol(fileName);' with code to set up
%   the V struct manually. This fixes a bug where an existing image
%   transform 'mat' file would be read in a replace our carefully
%   calculated scale factors. (This bug would not affect those who don't
%   use the spm-style '.mat' transform files.)
%   2004.07.27 RFD: Removed SPM99 dependency. We now use a modified version 
%   of Worsley's fmris_write_analyze.
%   2004.10.19 AG: Added version check for Matlab7 compatibility
%   datestr(now) format changed, used date instead
%
% BOB (c) Stanford VISTASOFT, 2002

if (~exist('mmPerVox','var') | isempty(mmPerVox))
    if(ndims(imArray==4)) mmPerVox = [1 1 1 1];
    else mmPerVox = [1 1 1]; end
end

% datestr(now) format changed, used date instead 
if (~exist('notes','var') | isempty(notes))
    matlabVersion=ver('Matlab');
    majorVersion = str2num(matlabVersion.Version(1));
    if (majorVersion>=7) 
        notes = ['Created by saveAnalyze on ',date];
    else 
        notes = ['Created by saveAnalyze on ',datestr(now)]; 
    end
end

imDim = size(imArray);
if (~exist('origin','var') | isempty(origin))
    origin = (imDim(1:3)+1)./2;
end

d.file_name = [fileName '.img'];
d.data = imArray;
d.vox = mmPerVox;
d.vox_units = 'mm';
d.vox_offset = 0;
d.calib_units = 'min^-1';
d.origin = origin;
d.descrip = notes;
switch(class(imArray))
    case {'uint8','int16','int32'}
        d.precision = class(imArray);
    case {'logical'}
        d.precision = 'uint1';
    otherwise 
        d.precision = 'float';
end
disp(['saving data as ' d.precision '...']);
d = fmris_write_analyze(d);
hdr = d;

% s = spm_hwrite(fileName, imDim, mmPerVox, 1, spm_type('int16'), 0, origin, notes);
% %V = spm_vol(fileName);
% V.fname = fileName;
% V.dim = [imDim spm_type('int16')];
% % Offset is from center of image
% offset = -mmPerVox.*origin;
% V.mat = [mmPerVox(1) 0 0 offset(1) ; 0 mmPerVox(2) 0 offset(2) ; 0 0 mmPerVox(3) offset(3) ; 0 0 0 1];
% V.pinfo = [1 0 0]';
% V.descrip = notes;
% 
% hdr = spm_write_vol(V, imArray);

return