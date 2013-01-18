function niftiWriteMatlab(ni,fileName)
% Write a VISTASOFT nifti structure into a file compatible with the NIFTI-1
% standard.
% 
%   niftiWriteMatlab(ni,fileName)
%
% INPUTS:
%   ni       - a nifti file structure (.nii or .nii.gz)
%   fileName - Name of the file to save.
%              If saving an OLD VISTASOFT nifti fileName is not necessary,
%              otherwise it is required.
%
% OUTPUTS:
%   none.
%
% Web Resources:
%   mrvBrowseSVN('niftiWriteMatlab')
%
% Example:
% 
% >> niftiWriteMatlab(ni);
%	
% Franco (c) Stanford VISTA team, 2012
%
% This matlab version has been adapted by Franco from Bob's c-code

%% Deal with ol VISTASOFT nifti structures.
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
