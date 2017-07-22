function test_exportNiftiParameterMap()
%Test functionals2nifti 
%
%   test_exportNiftiParameterMap()
%
%
% Tests: functionals2nifti and niftiRead 
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example: test_exportNiftiParameterMap()
%
% See also MRVTEST 
%
% Copyright NYU team, mrVista, 2017
%


% Use a sample data set for testing
dataDir = mrtInstallSampleData('functional', 'erniePRF');


% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

dt = 'Averages';
scan = 1;

% open a hidden volume view
vw = initHiddenGray;
vw = viewSet(vw, 'current dt', dt); 
vw = viewSet(vw, 'current scan', scan); 

vw = rmSelect(vw, 1, 'rmOneGaussian-fFit-fFit-fFit.mat'); 
vw = rmLoadDefault(vw); 


% Export the phase and coherence maps
vw = viewSet(vw, 'display mode', 'ph');
functionals2nifti(vw,scan, 'myPhaseMap.nii.gz');

vw = viewSet(vw, 'display mode', 'co');
functionals2nifti(vw,scan, 'myCoMap.nii.gz');

% Load gray/white class file and new phase and co files
cls = niftiRead(fullfile('3DAnatomy', 't1_class.nii.gz'));
ph  = niftiRead('myPhaseMap.nii.gz');
co  = niftiRead('myCoMap.nii.gz');

% Check that all non-zero values of co and phase are in voxels with
% nonzero class values. This will be true if the images are aligned.
idx = ph.data ~= 0;
assert(all(cls.data(idx)))

idx = co.data ~= 0;
assert(all(cls.data(idx)))

% Check the headers
assertEqual(cls.qto_xyz, ph.qto_xyz);

% return to original directory
cd(curDir);