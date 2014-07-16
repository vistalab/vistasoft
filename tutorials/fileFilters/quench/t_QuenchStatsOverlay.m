%t_QuenchStatsOverlay
%
%  This tutorial illustrates how to overlay colors on a fiber tract and
%  visualize the result in Quench.  The example shows how to overlay FA on
%  a tract.
%
%  To show an overlay we create data in a NIFTI file format that is in the
%  same coordinate frame as the fiber tract (in a pathway database - pdb)
%  format. The NIFTI file structure has the parameters as the b=0 voxels
%  diffusion data.
%
%  1. We read in the pdb data using mtrImportFibers
%  2. In this case we create a NIFTI file structure and place the FA data in
%  that data structure. 
%  3. We pass the fiber tract and the NIFTI structure into the function
%  dtiCreateQuenchStats.  This produces an output file that contains the
%  statistics Quench needs for the visualization.
%
%
% Original from Jason Yeatman
%
%%

%Load Fiber Group
fg=mtrImportFibers('/biac3/wandell4/data/reading_longitude/dti_adults/rb080930/fibers/conTrack/L_OpticRad_JY_20000.pdb');

%load eccentricity map
ec=niftiRead('/azure/scr1/vistadata/wmRetinotopy/functional/rb_eccentricity_18-Feb-2011.nii.gz');

%Load quantitative maps
hlf=niftiRead('/biac3/wandell5/data/relaxometry/HLF15T15mm/rb1_5T_1_5mms/HLFB1.nii.gz');
wf=niftiRead('/biac3/wandell5/data/relaxometry/HLF15T15mm/rb1_5T_1_5mms/Wf.nii.gz');

%turn wf into tf
wf.data=1-wf.data;

%create an FA map. first we need to load the dt6 file
dt=dtiLoadDt6('/biac3/wandell4/data/reading_longitude/dti_adults/rb080930/dti06trilin/dt6.mat');
b0=niftiRead('/biac3/wandell4/data/reading_longitude/dti_adults/rb080930/dti06trilin/bin/b0.nii.gz');

% creating a new nifti image with the same header info as the b0
fa=b0;

%and then computing FA and putting in the data area of the image
fa.data=dtiComputeFA(dt.dt6);

%Now compute stats on fiber group
fg=dtiClearQuenchStats(fg);
fg=dtiCreateQuenchStats(fg,'FA_ave','FA',1,fa,'avg',[],[.2 .8]);
fg=dtiCreateQuenchStats(fg,'HLF_ave','HLF',1,hlf,'avg');
fg=dtiCreateQuenchStats(fg,'TF_ave','TF',1,wf,'avg',[],[.3 .5]);
%we jdon't have this eccentricity map done properly
fg=dtiCreateQuenchStats(fg,'EC_ave','EC',1,ec,'avg','matchend');

%write out fiber group with stats
mtrExportFibers(fg,'/biac3/wandell4/data/reading_longitude/dti_adults/rb080930/fibers/conTrack/scoredFgOut_top5000_lLGN2V1+stats.pdb');

%% We made pretty pictures now lets make it look scientific!  We'll plot
% the values alongt the length of the fiber group weighting fibers closer
% to the core
dFallOff=1;%the rate of fall off for weighting fibers
[faVals, SuperFiber, weightsNormalized]=dtiFiberGroupPropertyWeightedAverage(fg, dt, 50, 'fa',dFallOff);
[tfVals, SuperFiber, weightsNormalized]=dtiFiberGroupPropertyWeightedAverage(fg, wf, 50, 'image',dFallOff);

figure;
plot([1:50],faVals,'r','lineWidth',2);xlabel('Node');
hold on
plot([1:50],tfVals,'k--','lineWidth',2);
legend({'FA','TF'})

grid on

