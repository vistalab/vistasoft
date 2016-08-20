function ni = niftiRead(fileName, volumesToLoad)
% Matlab wrapper to call the mex readFileNifti
%
%   niftiImage = niftiRead(fileName,volumesToLoad)
%
% Reads a NIFTI image and populates a structure that should be the
% NIFTI 1 standard
%
% If volumesToLoad is not included in the arguments, all the data
% are returned.
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

% This normally calls the mex file for your system
if ~exist('fileName','var') || isempty(fileName)
    % Return the default structure.  Equivalent to niftiCreate
    % ni = niftiRead;
    ni = readFileNifti;
elseif ischar(fileName) && exist(fileName,'file')
    % fileName is a string and the file exists.
    % For some reason, the volumeToLoad is not yet implemented.
    % We should just implement it here, by reading the whole
    % thing and only returning the relevant volumes.  I think
    % that is represented by the 4th dimension, but I should ask
    % someone who knows.
    if exist('volumesToLoad','var')
        % ni = niftiRead('foo.nii.gz',1:20);
        % We let readFileNifti complain about not implemented for
        % now.
        ni = readFileNifti(fileName,volumesToLoad);
    else
        % ni = niftiRead('foo.nii.gz');
        ni = readFileNifti(fileName);
    end
else
    % Did the person not include the .nii.gz extensions?
    [~,n,e] = fileparts(fileName);
    if isempty(e), fileNameExtended = [n,'.nii.gz']; end
    if exist(fileNameExtended,'file')
        ni = readFileNifti(fileNameExtended);
    else
        error('Cannot find the file %s or %s\n',fileName,fileNameExtended);
    end
end

% When there is a niftiGet, this can go away.
ni.data_type = niftiClass2DataType(class(ni.data));

return
