% adjust ROIs for new dt6s
%load each dt6, get FA data too, load the LOcc_new, ROcc_new rois, edit
%ROI: dilate with a 8mm kernel+fill holes, and then restrict to FA>0.2
%save new ROI as LOcc_adjusted, ROcc_adjusted. 
%track fibers from each ROI and save fiber groups.
%
% 20050423 mbs wrote it


%for adults:
baseDir = '//snarp/u1/data/reading_longitude/dti_adults'; %on Teal
% baseDir = '\\snarp\u1\data\reading_longitude\dti_adults';% on cyan
f = {'ab050307','as050307','aw040809','bw040806','da050311','gm050308',...
        'jl040902','ka040923','mbs040503', 'me050126', 'mz040828',...
        'pp050208', 'rd040630','sn040831','sp050303'};

%for children:
clear all;
baseDir = '//snarp/u1/data/reading_longitude/dti'; %running on Teal
%fileNameFragment = '_dt6';
% baseDir = '\\snarp\u1\data\reading_longitude\dti';% running on cyan
f = findSubjects1; %check that this gets all 55 datasets

%params for restrict and smooth old ROI
faThresh = 0.2;
smoothKernel = 8;

%params for tracking
opts.stepSizeMm = 1;
opts.faThresh = 0.15;
opts.lengthThreshMm = 20;
opts.angleThresh = 30;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [0.25 0.75];

for(ii=1:length(f))
    cd(fileparts(f{ii}));
    fname = f{ii}; 
    disp(['Processing ' fname '...']);
    roiPath = fullfile(fileparts(f{ii}), 'ROIs');
    fiberPath = fullfile(fileparts(f{ii}), 'fibers');
    dt = load(fname);
    dt.dt6(isnan(dt.dt6)) = 0;
    dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
    [eigVec, eigVal] = dtiSplitTensor(dt.dt6);
    clear eigVec;
    fa = dtiComputeFA(eigVal);
    clear eigVal;
  
    %left ROI: load, clean,restrict, write
    LroiOldName = 'LOcc_new';
    LroiNewName = 'LOcc_adjusted';
    %clean the left ROI
    Lroi = dtiReadRoi(fullfile(roiPath,LroiOldName));
    Lroi = dtiRoiClean(Lroi, smoothKernel, {'dilate'});
    %restrict to fa thresh
    ic = mrAnatXformCoords(inv(dt.xformToAcPc), Lroi.coords);% 
    sz = size(fa);
    ic = round(ic);
    %first throw out any coords that's outside the frame
    keep = ic(:,1)>1 & ic(:,1)<=sz(1) & ic(:,2)>1 & ic(:,2)<=sz(2) & ic(:,3)>1 & ic(:,3)<=sz(3);
    ic = ic(keep,:);
    Lroi.coords = Lroi.coords(keep,:);
    imgIndices = sub2ind(sz, ic(:,1), ic(:,2), ic(:,3));
    keepCoordInd = fa(imgIndices)>=faThresh;
    Lroi.coords = Lroi.coords(keepCoordInd, :);
    Lroi.name = LroiNewName;
    dtiWriteRoi(Lroi, fullfile(roiPath,LroiNewName));
    clear ic sz keep imgIndices keepCoordInd;
    
    %right ROI: load, clean,restrict, write
    RroiOldName = 'ROcc_new';
    RroiNewName = 'ROcc_adjusted';
    %clean the right ROI
    Rroi = dtiReadRoi(fullfile(roiPath,RroiOldName));
    Rroi = dtiRoiClean(Rroi, smoothKernel, {'dilate'});
    %restrict to fa thresh
    ic = mrAnatXformCoords(inv(dt.xformToAcPc), Rroi.coords);% 
    sz = size(fa);
    ic = round(ic);
    keep = ic(:,1)>1 & ic(:,1)<=sz(1) & ic(:,2)>1 & ic(:,2)<=sz(2) & ic(:,3)>1 & ic(:,3)<=sz(3);
    ic = ic(keep,:);
    Rroi.coords = Rroi.coords(keep,:);
    imgIndices = sub2ind(sz(1:3), ic(:,1), ic(:,2), ic(:,3));
    keepCoordInd = fa(imgIndices)>=faThresh;
    Rroi.coords = Rroi.coords(keepCoordInd, :);
    Rroi.name = RroiNewName;
    dtiWriteRoi(Rroi, fullfile(roiPath,RroiNewName));
    clear ic sz keep imgIndices keepCoordInd;

    Lfg = dtiFiberTrack(dt.dt6, Lroi.coords, dt.mmPerVox, dt.xformToAcPc, LroiNewName,opts);
    Rfg = dtiFiberTrack(dt.dt6, Rroi.coords, dt.mmPerVox, dt.xformToAcPc, RroiNewName,opts);
    dtiWriteFiberGroup(Lfg, fullfile(fiberPath, Lfg.name), 1, 'acpc');
    dtiWriteFiberGroup(Rfg, fullfile(fiberPath, Rfg.name), 1, 'acpc');
    clear Lfg Rfg Lroi Rroi;
end



