%% dtiInit validation function
%
% Download example data from the RDT
% Set default parameters for rapid processing, excluding eddy current
%
% Run dtiInit and we will set some numbers to check for asserts.
%
% RL/BW Vistasoft Team, 2016


%% Get the example diffusion weighted imaging data from the RDT

rd = RdtClient('vistasoft');
rd.crp('/vistadata/diffusion/dtiInit/raw');
rd.listArtifacts('print',true)

rd.readArtifact('dti','type','bvec','destinationFolder',pwd);
rd.readArtifact('dti','type','bval','destinationFolder',pwd);
rd.readArtifact('dti.nii','type','gz','destinationFolder',pwd);

rd.crp('/vistadata/diffusion/dtiInit');
rd.listArtifacts('print',true)
rd.readArtifact('t1.nii','type','gz','destinationFolder',pwd);

%%

dwRawFileName = fullfile(pwd,'dti.nii.gz');
t1FileName = fullfile(pwd,'t1.nii.gz');
niT1 = niftiRead(t1FileName);

params = dtiInitParams;
params.eddyCorrect    = -1;  % This takes a long time so we turn eddy current and motion correction
params.phaseEncodeDir = 2;   % We have super powers and know this
params.clobber = true;       % Silently over-write files.
params.dwOutMm = niT1.pixdim;% Match the T1 so we can crop together

params.outDir = fullfile(vistaRootPath,'local');         % Stash output
[dt6FileName, outBaseDir] = dtiInit(dwRawFileName,t1FileName,params);

%%
slices = 50:59;
niftiView('dti_aligned_trilin_noMEC.nii.gz','slices',slices);
niftiView('t1.nii.gz','slices',slices);

% Original, before upsampling
niftiView('dti_b0.nii.gz','slices',slices);

% Can we show the white matter mask on top of the dti_aligned?

