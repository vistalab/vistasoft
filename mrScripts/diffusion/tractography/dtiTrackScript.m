
[f,p] = uigetfile('*.mat', 'Load the dt6 file');
fname = fullfile(p,f);
if(exist(fullfile(p,'fibers'),'dir')) fiberPath = fullfile(p,'fibers');
else fiberPath = p; end


faThresh = 0.25;
opts.stepSizeMm = 1;
opts.faThresh = 0.15;
opts.lengthThreshMm = 20;
opts.angleThresh = 30;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [0.25 0.5];

dt = load(fname);
dt.dt6(isnan(dt.dt6)) = 0;
dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;

% Create WM ROIs
[eigVec, eigVal] = dtiSplitTensor(dt.dt6);
clear eigVec;
fa = dtiComputeFA(eigVal);
clear eigVal;
    
roiAll = dtiNewRoi('all');
mask = fa>=faThresh;
[x,y,z] = ind2sub(size(mask), find(mask));
roiAll.coords = mrAnatXformCoords(dt.xformToAcPc, [x,y,z]);
    
% LEFT ROI
roiLeft = dtiRoiClip(roiAll, [0 80]);
roiLeft = dtiRoiClean(roiLeft, 3, {'fillHoles', 'removeSat'});
roiLeft.name = 'allLeft';
dtiWriteRoi(roiLeft, fullfile(roiPath, roiLeft.name));

% RIGHT ROI
roiRight = dtiRoiClip(roiAll, [-80 0]);
roiRight = dtiRoiClean(roiRight, 3, {'fillHoles', 'removeSat'});
roiRight.name = 'allRight';
dtiWriteRoi(roiRight, fullfile(roiPath, roiRight.name));

fg = dtiFiberTrack(dt.dt6, roiLeft.coords, dt.mmPerVox, dt.xformToAcPc, ...
                   [roiLeft.name 'FG'], opts);
dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc');
clear fg;
fg = dtiFiberTrack(dt.dt6, roiRight.coords, dt.mmPerVox, dt.xformToAcPc, ...
                   [roiRight.name 'FG'], opts);
dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc');
clear fg;
