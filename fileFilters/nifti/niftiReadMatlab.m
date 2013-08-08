function nii = niftiReadMatlab(fileName, volumesToLoad)
%
% Reads a NIFTI-1 file into a VISTASOFT nifti structure.
%       See http://nifti.nimh.nih.gov/nifti-1/
%
%  niftiImage = niftiReadMatlab(fileName, [volumesToLoad=-1])
%
% fileName      - path to a .nii or nii.gz file.
% VolumesToLoad - The optional second argu specifies which volumes 
%                 to load for a 4D dataset. The default (-1) means 
%                 to read all, [] (empty) will just return the header.
%
% Call this function with no arguments to get an empty structure.
%
% NOTE: this file contains a slow maltab implementation of a compiled
% mex function. If you get a warning that the mex function is not being
% called, then compiling niftiReadMatlab.c will dramatically improve
% performance.
%
% Example:
%   ni = niftiReadMatlab;   % Nifti-1 structure
%
% (c) Stanford Vista 2012

if notDefined('volumesToLoad') || volumesToLoad==-1
    volumesToLoad = [];
end

% Build a filename and save it into the structure.
[~,f,e]  = fileparts(fileName);

% Load the nifti file.
if(strcmpi(e,'.gz'))
   tmpDir = tempname;
   mkdir(tmpDir);
   copyfile(fileName,fullfile(tmpDir,strcat(f,e)));
   gunzip(fullfile(tmpDir,strcat(f,e)));
   tmpFileName = fullfile(tmpDir, f);
   tmpFile = true;
   nii = load_untouch_nii(tmpFileName, volumesToLoad);
else
   tmpFile = false;
   nii = load_untouch_nii(fileName, volumesToLoad);
end

% Transform into VISTASOFT nifti-1 structure
nii = niftiNi2Vista(nii);

% Delete the temporary file created
if ( tmpFile )
    delete(tmpFileName);
end

end
