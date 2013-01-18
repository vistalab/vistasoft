function functionals2itkGray(vw, scan, outpth)
% 
% functionals2itkGray(vw, [scan], [outpth])
% 
% AUTHOR:  JW (ported from functionals2mrGray)
% DATE:  jan, 2009
% PURPOSE:
%   Writes out the functional data currently on display in the
%   volume window into a nifti file that can be read in by
%   itkGray or Quench as an overlay file.
%   
% vw: structure that contains all the information
%       related to the volume functional data and user interface.
% 
%
% Example: Export the current map
%   vw = getSelectedGray;
%   functionals2itkGray(vw);


%% functionals2itkGray(VOLUME{1});
mrGlobals;

% Figure out which scan is being viewed.
if notDefined('scan'), scan = viewGet(vw, 'curscan'); end

% Extract the data being displayed and the corresponding locations
dataIN = getCurData(vw, viewGet(vw, 'displayMode'), scan);

% Convert mrVista format to our preferred axial format for NIFTI
mmPerVox = viewGet(vw, 'mmPerVox');
data = mrLoadRet2nifti(dataIN, mmPerVox); 

%Load up t1 to get xforms correct
[t1Path, t1Name, ext] = fileparts(vANATOMYPATH);

if isempty(strmatch(ext, {'.ni', '.nii', '.gz'}))
    [t1Name t1Path]=uigetfile('*.nii.gz','Select T1 anatomy for nifti header');
    pth = fullfile(t1Path, t1Name);
else
    pth = vANATOMYPATH;
end

ni=readFileNifti(pth);

ni.data = data;

% name and path to save file
if notDefined('outpth'), ni.fname = fullfile(t1Path, ['functionalOverlay-' datestr(now,1) '.nii.gz']);
else  ni.fname = outpth; end
    
writeFileNifti(ni);

message = sprintf('Functional data saved as %s.\n', ni.fname);
disp(message);

return;


