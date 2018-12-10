function test_importNiftiROI()
%Test roiSaveAsNifti and nifti2ROI 
%
%   test_importNiftiROI()
%
%
% Tests: roiSaveAsNifti and nifti2ROI 
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_importNiftiROI()
%
% See also MRVTEST 
%
% Copyright Stanford team, mrVista, 2016
%


% Use a sample data set for testing
dataDir = mrtInstallSampleData('functional', 'mrBOLD_01');


% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% open a hidden view
vw = initHiddenGray;

% Create a new ROI
vw = newROI(vw);

% Give the ROI some arbitrary coordinates
x = repmat(100, 1,10);
y = repmat(90, 1, 10);
z = 31:40;
vw = viewSet(vw, 'ROI coords', [x; y; z], 1);

% Export the ROI as a nifti file
roiSaveAsNifti(vw, 'myNewROI.nii'); 

% Import the nifti ROI into the view structure
vw = nifti2ROI(vw, 'myNewROI.nii');

% Check that coords for exported and imported ROIs match 
assertEqual(viewGet(vw, 'roi coords', 1), viewGet(vw, 'roi coords', 2))

% return to original directory
cd(curDir);