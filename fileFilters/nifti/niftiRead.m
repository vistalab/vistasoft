function ni = niftiRead(fileName, volumesToLoad, threshold)
% Matlab wrapper to call the mex readFileNifti or niftiReadMatlab
%
%   niftiImage = niftiRead(fileName,volumesToLoad)
%
% Reads a NIFTI image and populates a structure that should be the
% NIFTI 1 standard
%
% If volumesToLoad is not included in the arguments, all the data
% are returned. If volumesToLoad is empty ([]) returns only the header
%
% This function calls 
% readFileNifti: memory efficient
% or 
% niftiReadMatlab: slow, but robust for nifti file with large size
% depending on the file size. (We can define the selection criteria by
% using parameter "threshold")
% 
% Web Resources
%  web('http://nifti.nimh.nih.gov/nifti-1/','-browser')
%
% See also:  niftiCreate, niftiGetStruct
%
% Example:
%  niFile = fullfile(mrvDataRootPath,'mrQ','T1_lsqnabs_SEIR_cfm.nii.gz');
%  ni = niftiRead(niFile);
%
% Copyright, Vista Team Stanford, 2011
% History:
% 2017.07: HT included the option to call two functions depending on file
% size

% Default threshold = 3GB. If the file size exceeds this limit, we use
% niftiReadMatlab, not readFileNifti
if notDefined('threshold'), threshold = 3221225472; end

% Get file size
fileinfo = dir(fileName);

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
        if fileinfo.bytes < threshold
            ni = readFileNifti(fileName,volumesToLoad);
        else
            ni = niftiReadMatlab(fileName,volumesToLoad);
        end
    else
        % ni = niftiRead('foo.nii.gz');
        if fileinfo.bytes < threshold
            ni = readFileNifti(fileName);
        else
            ni = niftiReadMatlab(fileName);
        end
    end
else
    % Did the person not include the .nii.gz extensions?
    [~,n,e] = fileparts(r);
    if isempty(e), fileNameExtended = [n,'.nii.gz']; end
    if exist('fileNameExtended', 'var') ...
            && exist(fileNameExtended,'file')
        if fileinfo.bytes < threshold
            ni = readFileNifti(fileNameExtended);
        else
            ni = niftiReadMatlab(fileNameExtended);
        end
    else
        error('Cannot find the file %s or %s\n',fileName,fileNameExtended);
    end
end
end
