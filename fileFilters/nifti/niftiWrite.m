function niftiWrite(ni,fName)
% Matlab wrapper for writeFileNifti. Writes a nifti structure to disk. 
%
%   niftiWrite(ni,[fName])
%
% If nifti data are int16, uses the fast mex-file write.  Otherwise it uses
% the NIFTI-1 implementation in Matlab from Shen. The Matlab implementation
% preserves NaNs, but the mex-version we implemented fails to preserve
% them.
% 
% INPUTS
%   ni - a nifti file structure 
%   fName - output file name  (defaults to ni.fname). 
%
% Web Resources:
%   mrvBrowseSVN('niftiWrite');
% 
% Example:
%   ni = niftiRead('niftiFile.nii.gz');
%   fName = 'myFile.nii.gz'
%   niftiWrite(ni,fName);
%
% See also:  niftiCreate, feWriteValues2nifti
% 
% (C) Stanford VISTA, 2012


%% Check inputs

% If the filename does not include an extension we assign one here.
if exist('fName','var'),  ni.fname = fName; end
[p f e] = fileparts(ni.fname);
if isempty(e), ni.fname = fullfile(p,[f '.nii.gz']); end


%% Write using a function that depends on the nifti data type field 
% Files are written out in a format complaint with the NIFTI-1 file type.
% Jimmy Shen's code and VISTASOFT code can read these files.
% But, the mex file we have only handle one data type: int16.
% switch ni.data_type
%     case  niftiClass2DataType('int16')
%         writeFileNifti(ni);   % Fast, mex-file
%     otherwise
        niftiWriteMatlab(ni);
% end


end