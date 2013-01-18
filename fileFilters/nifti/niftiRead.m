function ni = niftiRead(fileName, volumesToLoad)
% Matlab wrapper to call the mex readFileNifti
%
%   niftiImage = niftiRead(fileName)
%
% Reads a NIFTI image and populates a structure that should resemble the
% NIFTI 1 standard 
%
% If volumesToLoad is not included in the arguments, the data are returned.
%    volumesToLoad is empty [] returns only the header
%
% Web Resources
%  web('http://nifti.nimh.nih.gov/nifti-1/','-browser')
%  mrvBrowseSVN('niftiRead.m')
%
% See also:  niftiCreate, niftiGetStruct
%  
% Example:
%  niFile = fullfile(mrvDataRootPath,'mrQ','T1_lsqnabs_SEIR_cfm.nii.gz');
%  ni = niftiRead(niFile);  
%
% Copyright, Vista Team Stanford, 2011

% We are testing niftiReadMatlab.  Not sure we need it yet.  By we, I mean
% Franco.

% This normally calls the mex file for your system
if ~exist('fileName','var') || isempty(fileName)
    % Return the default structure.  Equivalent to niftiCreate
    ni = readFileNifti;
elseif exist('volumesToLoad','var')
    ni = readFileNifti(fileName,volumesToLoad);
else
    ni = readFileNifti(fileName);
end

% When there is a niftiGet, this can go away.
ni.data_type = niftiClass2DataType(class(ni.data));

return
