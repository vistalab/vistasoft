function ni = readFileNifti(fileName, volumesToLoad)
%
% Reads a NIFTI-1 file into a VISTASOFT nifti structure.
%       See http://nifti.nimh.nih.gov/nifti-1/
%
%  niftiImage = readFileNifti(fileName, [volumesToLoad=-1])
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
% called, then compiling readFileNifti.c will dramatically improve
% performance.
%
% Example:
%   ni = readFileNifti;   % Nifti-1 structure
%
% (c) Stanford Vista 2012

disp('Using the m-file niftiReadMatlab rather than the compiled mex function.');
if(nargin==0)
    if(nargout==0)
        help(mfilename);
    else
        ni = getVistaNiftiStructure;
        return;
    end
end

if(~exist('volumesToLoad','var') || volumesToLoad==-1)
    volumesToLoad = [];
end

% Get a structure for the nifti file compatible with VISTASFOT
ni = niftiReadMatlab(fileName, volumesToLoad);

end
