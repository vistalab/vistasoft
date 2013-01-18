% Script to extract gray matter from pial and smoothwm surfaces
% Uses mri_surfacemask routine. Only runs on RH / i386 I think

fs_dir='/raid/MRI/toolbox/MGH/freesurfer/bin/Linux';
fsl_dir='/raid/MRI/toolbox/FSL/fsl/bin/';

hemi='rh';
subjid='norcia_fs_WB';

% Run mri_surfacemask on both the rh.smoothwm and rh.pial
fileBase=['/raid/MRI/anatomy/FREESURFER_SUBS/',subjid];
fileNameToProcess=[fileBase,'/surf/',hemi,'.pial'];
anatomyToUse=[fileBase,'/mri/T1/'];
outFileName=[fileBase,'/mri/',hemi,'_pial'];
fs_command=['echo ',fs_dir,'/mri_surfacemask ',anatomyToUse,' ',fileNameToProcess,' ',outFileName,'.img | csh'];
disp(fs_command);
tic

system(fs_command);
toc
% Load in the pial image
[pialIm,dims,scalesmbpp,endian]=read_avw([outFileName]);

fileNameToProcess=[fileBase,'/surf/',hemi   ,'.smoothwm'];
outFileName=[fileBase,'/mri/',hemi,'_smoothwm'];
fs_command=['echo ',fs_dir,'/mri_surfacemask ',anatomyToUse,' ',fileNameToProcess,' ',outFileName,'.img | csh'];
disp(fs_command);
tic
dos(fs_command);
toc

% Load in the smoothwm image
[wmIm,dims,scalesmbpp,endian]=read_avw(outFileName);

% Binarize and 'and' them
wmIm(wmIm>0)=1;

pialIm(pialIm>0)=1;
grayIm=pialIm-wmIm;
grayIm(grayIm~=1)=0;
grayIm(grayIm~=0)=255;

outFileName=[fileBase,'/mri/',hemi,'_grayMask'];
grayIm=permute(grayIm,[1 3 2]);

save_avw((grayIm),outFileName,'b',scalesmbpp);
    
% Resulting analyze files can be imported to EMSE and a region defined on
% them using the thresholding / growing routines.
% The dimensions are ordered correctly but must be flipped front/back,
% top/bottom AND left/right!

