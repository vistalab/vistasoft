function [img, mmPerVox, hdr, filename, fullHeader] = analyzeRead(filename, endianType, nativeTypeFlag, overrideScale)
% function [img, mmPerVox, hdr, filename, fullHeader] = analyzeRead(analHeaderFileName, ...
%   [endianType], [nativeTypeFlag], [overrideScale]);
%
% Reads Analyze7.5 image data into a matlab array 'img'. 
% Certain parts of the Analyze header info are stored in 'hdr'.
%
% If you pass in the (optional) endianType it will use this when
% reading 16bit data files. Defaults to 'ieee-le' (little-endian- intel).
% Another common option is 'ieee-be' (big-endian, ie. non-intel).
% NOTE: as of 2004.02.25, the endianType is automatiacally determined, so
% this parameter is not needed and should go away. It is currently silently
% ignored.
%
% If nativeTypeFlag is 1 (default = 0), then the data are returned in an
% array of the same type as the file data. Eg. int16, uint8, etc.
%
% If overrideScale is passed, the passed value is used to scale the data
% rather than the value in the Analyze file header.  This is useful for
% incorrectly formated Analyze files.
%
% After this routine scales the image data, it sets the scale factor in
% returned hdr.pinfo(1) = 1.  This allows backward compatibility with
% routines that performed the scaling outside of this routine, before
% we folded the scaling in.  We don't see any obvious problem with this
% action, but it does deviate from what you would get if you used the
% routine pair hdr = spm_vol(filename); img = spm_read_vols(hdr).  This
% would result in the returned data being scaled (as here), but the hdr
% would in that case still have the scale factor used.
%
% NOTE: as of 2004.02.25, the hdr.dim(4) value is no longer spm-compatible.
% Spm uses this 4th dimension to store the data type. We now return that
% separately. Thus, we are ready to allow 4-dimensional data files.
%
% REQUIRES:
%   No longer requires spm code. We now use a function adapted from
%   Worsley's fmristat (http://www.math.mcgill.ca/~keith/fmristat/)
%   This function (fmris_read_analyze) should be in our repository.
%
% SEE ALSO: analyze2mrGray, mrGray2Analyze, spm_read_vols
%  In particular, analyze2mrGray provides an example of how to orient the
%  data for mrGray.
% s
% HISTORY:
%   2001.12.13 RFD (bob@white.stanford.edu) wrote it.
%   2003.06.13 DHB (brainard@psych.upenn.edu)  Change comment above,
%       as default for nativeTypeFlag is in fact 0 as coded, not 1 as
%       the previous comment said. 
%  2003.06.18  DHB (brainard@psych.upenn.edu)  Multiply read image data 
%       by scale factor in header.  Set this scale factor to 1 in returned
%       data.  Also added overrideScale arg.   This change made after
%       consultation with RFD.
%  2003.07.03 RFD Fixed typo-looking bug that prevented the scale factor
%       from getting set to 1. 
%  2004.01.06 RFD: Replaced "hdr = spm_vol(filename);" with the relevant
%  lines of code from that spm function. We do this because the mmPerVox
%  value in the Analyze header is more likely to be accurate than the one
%  in the spm space-transform 'mat' file. That scale factor is still
%  available in the transform matrix (hdr.mat). Note that this change will
%  only affect those of us who dare to use the spm-style transform files
%  with our analyze data. (This is a third file, in addition to the .img
%  and .hdr files, that is a matlab 'mat' file containing extra spatial
%  transform info that doesn't fit into the Analyze header, such as a full 
%  affine transform.)
%  2004.02.25 RFD: Removed spm-dependent code. We now use a function
%  adapted from FMRISTAT (fmris_read_analyze).
%

if ~exist('filename','var') | isempty(filename)
   [fname, fpath] = uigetfile({'*.img','Analyze 7.5 format (*.img)'}, 'Select analyze volume file...');
   filename = [fpath fname];
   if fname == 0  % user cancelled
      return;
   end
end
%[p,f,ext] = fileparts(filename);

% Fix filename to point to the .img file.
[p,f,e] = fileparts(filename);
if(strcmpi(e,'.hdr')) 
    filename = fullfile(p,[f '.img']);
elseif(isempty(e) | ~strcmpi(e,'.img'))
    % This will allow dots in the filename
    filename = [filename '.img'];
end
baseFilename = filename(1:end-4);

% Note that the following applies the scale factor for us.
d = fmris_read_analyze(filename);
img = d.data;
mmPerVox = d.vox(1:3);
filename = d.file_name;
fullHeader = d.hdr;
hdr.fname = d.file_name;
hdr.dim = d.dim;
% build spm-style mat field
d.vox = d.vox(1:3);
%hdr.mat = [[diag(d.vox), [d.origin.*-d.vox-d.vox./2]']; [0 0 0 1]];
hdr.mat = [[diag(d.vox), [d.origin.*-d.vox]']; [0 0 0 1]];
hdr.pinfo = [d.scale;0;d.vox_offset];
hdr.descrip = d.descrip;

% NOTE: no longer needed- fmris_read_analyze automatically determins this.
if (exist('endianType','var') & ~isempty(endianType))
    disp([mfilename ': endianType no longer needed- it will be silently ignored.']);
end
if ~exist('nativeTypeFlag','var') | isempty(nativeTypeFlag)
    nativeTypeFlag = 0;
end
if ~exist('overrideScale','var') | isempty(overrideScale)
    overrideScale = 0;
end

% load an spm-style transform file, if it exists
xformFile = [baseFilename '.mat'];
if(exist(xformFile, 'file'))
    xform = load(xformFile);
    hdr.mat = xform.M;
end

% We could check the file size (d.bytes) against the expected number of bytes.
% d = dir(hdr.fname);
% if(length(d)<1)
%     error (['Could not find image file (',hdr.fname,') for this header file (',analHeaderFileName,').']);
% end

% Override scale factor in header?
% Note that the scale factor has already been applied, so we only have to
% apply and 'ajustment' if a different scale is desired.
if (overrideScale)
    hdr.pinfo(1) = overrideScale;
    img = overrideScale./hdr.pinfo(1).*img;
end

% Since the scale factor has been applied, we set it to 1 so that old code
% will still work.
hdr.pinfo(1) = 1;

if (nativeTypeFlag)
    eval(['img=' d.precision '(img);'], ...
        ['disp(''could not convert to native type "' d.precision '"'');']);
end

return
