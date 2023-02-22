%% t_fgCompute
%
% Examples of manipulating fiber groups and diffusion image data.
%
%
% (c) Stanford VISTA Team

% Make sure that vistadata is on your path
% vistaDataPath

%% Read the fibers and dwi data.
dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
dwi = dwiLoad(fullfile(dataDir,'raw','dwi.nii.gz'));

% Fibers are stored in ACPC space.
% We load up the dt6 and open a mrDiffusion window.  This brings in the
% xforms so that we can easily transform between image and acpc space.
dt6Name = fullfile(dataDir,'dti40','dt6.mat');
[dtiF, dtiH] = mrDiffusion('off',dt6Name);

fgName = fullfile(mrvDataRootPath,'diffusion','sampleData','fibers','leftArcuate.pdb');
xForm.img2acpc = dtiGet(dtiH,'img 2 acpc xform');
fgAcpc = mtrImportFibers(fgName,xForm,[],'acpc'); % Fiber coordinates in acpc space

% Create a version of the fiber group in image space for computations
xForm.acpc2img = dtiGet(dtiH,'acpc2img xform');
fgImg = dtiXformFiberCoords(fgAcpc,xForm.acpc2img,'img');

%  fLengths = fgGet(fgAcpc,'n nodes');
%  mrvNewGraphWin; hist(fLengths,100)

% Have a look at the fibers.  Visualizations are in ACPC space.
fgView(dtiH, fgAcpc); 

% But, if the 'img' coordspace was explicitly set upon xforming, this should appear the same (auto-xforms to acpc): 
fgView(dtiH, fgImg); 

% Now add the fiber-group to the dti handle: 
dtiH = dtiSet(dtiH,'add fiber group',fgAcpc);


%% Select an ROI
coords = fgGet(fgImg,'unique image coords'); 
size(coords,1)
meanCoord = round(mean(coords,1));


% Notice that if we find all the fibers in these coords, it should be all
% the fibers.
fgGet(fgImg,'n fibers')
v2fn  = fgGet(fgImg,'v2fn',coords);
% Every voxel has at least one fiber
for ii=1:length(v2fn)
    if isempty(v2fn{ii}), fprintf('%d\n',ii);end
end

% Now, do all the fibers show up in the roi?
fList = fgGet(fgImg,'fibers in roi',coords,v2fn);
length(fList)

%% remove fibers that do not go through the roi

% We could shrink coords to coords(1:5:end,:);
params.roiCoords = coords;
params.v2fn  = fgGet(fgImg,'voxel 2 fibernode pairs',coords);
fgNew = fgRestrict(fgImg,'roiCoords',params);
fprintf('Removed %i fibers because they did not go through the ROI coords.\n',length(fgNew.fibers) - length(fgImg.fibers))

%% Find unique fibers
origNFibers = length(fgNew.fibers);
fgNew = fgRestrict(fgNew,'uniquefibers',params);
fprintf('Kept %i unique fibers out of %i original fibers.\n',length(fgNew.fibers),origNFibers)

%% Make the list of tensors for each fiber and node
% These parameters could be adjusted to improve the quality of the fit.
d_ad = 1.5; d_rd = 0.5;
dParms(1) = d_ad; dParms(2) = d_rd; dParms(3) = d_rd;
fgNew.Q = fgTensors(fgNew,dParms);

%% build the MicroTrack model
[A dSig] = mctBuildDiffusionModel(dwi,fgNew,coords);

keyboard

%% Fit the model.
% Find the smallest number fo fibers that explain most of the variance in
% the diffusion data
computePrediction = 1;
displayResults   = 1;
[weights w predSig r2] = mctFitDiffusionModel(A,dSig,computePrediction,displayResults);

%% Compute model performance by cross-validation
EV       = mctDiffusionModelXvalidate(A,dSig);
fprintf('\nMicroTrack model performance %2.3f%% (Percent variance explained).\n',mean(EV));  
keyboard

%% Choose a subset in a smaller region of interest

% _NOT WORKING_  We shrink the coords but get more fibers, sigh.
%roiCoords = coords(50:5:end,:);
%roiCoords = coords([1],:);
%
%size(roiCoords)

%% Find only the fibers that pass through the smaller roiCoords

% There is something wrong now.
fgGet(fgImg,'nFibers')
params.roiCoords = roiCoords;
params.v2fn  = fgGet(fgImg,'voxel 2 fibernode pairs',roiCoords);
fgNew = fgRestrict(fgImg,'roi coords',params);
fgGet(fgNew,'nFibers')


