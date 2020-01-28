function ni = niftiRead(fileName, volumesToLoad)
% Matlab wrapper to call the mex readFileNifti
%
% *******************************************************
% NOTE:  As of 2017 Matlab has a "niftiread" function in its
%        distribution. 
% 
% NOTE: JAN 2020 GLU & JW: this version uses an external tool called nii_util.m 
%       taken from the toolset https://github.com/xiangruili/dicm2nii 
% *******************************************************
%
%   niftiImage = niftiRead(fileName,volumesToLoad)
%
% Reads a NIFTI image and populates a structure that should be the
% NIFTI 1 standard.  We expect that the filename has an extension of
% either .nii or .nii.gz
%
% If volumesToLoad is not included in the arguments, all the data
% are returned. If volumesToLoad is empty ([]) returns only the header
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
        % 
        % GLU EDIT: throw same error as the mex file
        % ni = readFileNifti(fileName,volumesToLoad);
        error('(volume selection) Not yet implemented!')
    else
        % Example:
        %     ni = niftiRead('foo.nii.gz');
        % Old call to the mex file
        %     ni = readFileNifti(fileName);
        % New called to the nii_tool wrapper
        ni = nii_tool_read_wrapper(fileName);
    end
else
    % Make sure the the file includes the .nii.gz extensions
    % Really, someone should 
    [p,n,e] = fileparts(fileName);
    if isempty(e), fileNameExtended = [p,filesep,n,'.nii.gz']; 
    else
        % The can be file.nii or file.nii.gz
        if strcmp(e,'.gz') || strcmp(e,'.nii')
            fileNameExtended = fileName;
        else
            warning('Unexpected file name extension %s\n',e);
        end
    end
    if exist(fileNameExtended,'file')
        % HERE WE MODIFY THE OLD VERSION
        % This is the old mex call
        % ni = readFileNifti(fileNameExtended);
        % This is the new call
        ni = nii_tool_read_wrapper(fileName);
    else
        error('Cannot find the file %s\n',fileNameExtended);
    end
end


end
