%% Test the niSelect function
%
% We identify a small region of a white matter mask.  We can use this
% region to limit the computation that we do for tracking and LiFE
%
% RL/BW Vistasoft Team, 2016

%% Go get a white matter mask from the Remote Data client

rdt = RdtClient('vistasoft');
rdt.crp('/vistadata/diffusion/sampleData/dti40/bin');

% This is all of the artifacts
a = rdt.listArtifacts('print',true);

% Write the white matter mask out in the local directory
dFolder = fullfile(vistaRootPath,'local');
fname = rdt.readArtifact(a(7),'destinationFolder',dFolder);

%% Have a look
nii = niftiRead(fname);
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

