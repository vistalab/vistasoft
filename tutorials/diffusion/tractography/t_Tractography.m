% Validate tractography on a small bit of white matter
%
%   1.  Download an existing diffusion sample data set from RDT
%   2.  Select a small part of the mask using niftiSelect
%   4.  Run tractography on the diffusion data with the small mask
%   5.  Visualize the tracts
%
% RL/BW Vistasoft Team, 2016

%% Download test data set

rdt = RdtClient('vistasoft');
rdt.crp('/vistadata/diffusion/zippedDirectory');

% This is all of the artifacts
aList = rdt.listArtifacts('print',true);

% Write the whole diffusion sample data directory
dFolder = fullfile(vistaRootPath,'local');
fname = rdt.readArtifact(aList(1),'destinationFolder',dFolder);
chdir(dFolder); unzip(fname);

%% Find the white matter mask and select out a cube

wmMask = fullfile(dFolder,'sampleData','dti40','bin','wmMask');
nii = niftiRead(wmMask);
p.keepLR = 20:30; p.keepPA = 20:30; p.keepIS = 40:50;
niiCube = niftiSelect(nii,p);
wmMaskCube = fullfile(dFolder,'sampleData','dti40','bin','wmMaskCube.nii.gz');
niftiWrite(niiCube,wmMaskCube);

% montageAll = niftiView(nii);
% montage = niftiView(niiCube);

%% Run a tractography algorithm


%% Visualize the tracts

