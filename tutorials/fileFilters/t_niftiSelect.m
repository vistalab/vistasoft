%% Test the niSelect function
%
% We identify a small region of a white matter mask.  We can use this
% region to limit the computation that we do for tracking and LiFE
%
% RL/BW Vistasoft Team, 2016

%% Go get a white matter mask from the Remote Data client

rdt = RdtClient('vistasoft');
rdt.crp('/vistadata/diffusion/zippedDirectory');

% This is all of the artifacts
a = rdt.listArtifacts('print',true);

% Write the white matter mask out in the local directory
dFolder = fullfile(vistaRootPath,'local');
fname = rdt.readArtifact(a(1),'destinationFolder',dFolder);
unzip(fname);

%% Have a look
% dwiFile = fullfile(vistaRootPath,'local','sampleData','dwi_aligned_trilin_noMEC');
% nii = niftiRead(dwiFile);

wmMask  = fullfile(vistaRootPath,'local','sampleData','dti40','bin','wmMask');
nii = niftiRead(wmMask);
montageAll = niftiView(nii);

%% Select out a cube

p.keepLR = 20:30; p.keepPA = 20:30; p.keepIS = 40:50;
niiCube = niftiSelect(nii,p);
montage = niftiView(niiCube);

%% Make an overlay from the
montageOverlay(:,:,1) = montage(:,:);
montageOverlay(:,:,2) = montageAll;
montageOverlay(:,:,3) = montageAll;
mrvNewGraphWin; imagesc(montageOverlay); axis image

%%

