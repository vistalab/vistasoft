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

%% Deal with old VISTASOFT nifti structures.
if isfield(ni,'data')
  % This is likely to be a old VISTASOFT nifti-1 structure, see
  % niftiVista2ni.m
  if notDefined('fileName'), fileName = ni.fname;end
  ni = niftiVista2ni(ni);
end

%% Save the file to disk using Shen's code.
if notDefined('fileName'), error('File name necessary to save a NIFTI-1 structure to file.');end
[p,n,e] = fileparts(fileName);
if isempty(e), n = sprintf('%s.nii',n);end
save_nii(ni,fullfile(p,n));

%% Zip the file
gzip(fullfile(p,n));

%% Delete the unzipped file created by save_nii.m:
delete(fullfile(p,n));


end