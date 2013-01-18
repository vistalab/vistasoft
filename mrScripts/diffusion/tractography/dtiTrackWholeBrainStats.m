% this script tracks whole brain and saves: # of fibers, mean length, std
% length, size of FA=0.2 mask

baseDir = '//snarp/u1/data/reading_longitude/dti_adults';%on teal
%baseDir = 'U:\data\reading_longitude\dti_adults';% on cyan
% baseDir = '//snarp/u1/data/reading_longitude/dti'; % for kids, if needed

f = {'ab050307','as050307','aw040809','bw040806','da050311','gm050308',...
        'jl040902','ka040923','mbs040503','me050126','mz040828',...
        'pp050208','rd040630','sn040831','sp050303'};% 15 subjects 6 directions only . run again for 23?
%f = {'mbs040503'}; %for debug
% f = findSubjects('','',{'tk040817','sl050516','dh050513','pf050514','mh050514','rh050514'}); % for kids, excluding tk and 2005 scans

faThresh = 0.2; %0.8 for debug on cyan to get a small group
opts.stepSizeMm = 1;
opts.faThresh = 0.15;
opts.lengthThreshMm = 20;
opts.angleThresh = 30;
opts.wPuncture = 0.2;
opts.whichAlgorithm = 1;
opts.whichInterp = 1;
opts.seedVoxelOffsets = [0.334 0.667];
lengthRanges = [20 40 60 80 100 120 140 160 180 200 inf]
nFibers = zeros(length(f),1);
nCoordsWM = zeros(length(f),1);
maxLength = zeros(length(f),1);
minLength = zeros(length(f),1);
meanLength = zeros(length(f),1);
medianLength = zeros(length(f),1);
stdLength = zeros(length(f),1);
histLengthFibers = zeros(length(f),length(lengthRanges));

for(ii=1:length(f))
    %fname = f{ii}; %for kids when using findsubjects
    fname = fullfile(baseDir, f{ii}, [f{ii} '_dt6.mat']);
    disp(['Processing ' fname '...']);
    dt = load(fname);
    dt.dt6(isnan(dt.dt6)) = 0;
    dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
    fa = dtiComputeFA(dt.dt6);
    
    %create a white matter mask
    roi = dtiNewRoi('wm');
    mask = fa>=faThresh;
    [x,y,z] = ind2sub(size(mask), find(mask));
    roi.coords = dtiXformCoords(dt.xformToAcPc, [x,y,z]);
    roi = dtiRoiClean(roi, 3, {'fillHoles', 'removeSat'});
    %save(fullfile(roiPath, roi.name), 'roi');
    wm = roi;
    
    %get ROI stats here - probably using dtiGetRoiStats but not clear how to
    %bypass handles
    %for now lets get coords as a measure of volume?
    
    nCoordsWM(ii) = size(wm.coords,1);
    
    % Track the whole brain
    fg = dtiFiberTrack(dt.dt6, wm.coords, dt.mmPerVox, dt.xformToAcPc, 'wholeBrain',opts);
    
    %Get stats
    fibers = fg.fibers;
    nFibers(ii) = length(fibers);
    lengths = zeros(1,nFibers(ii));
    for(i_fiber = 1:nFibers(ii))
        fiber = fibers{i_fiber};
        lengths(i_fiber) = length(fiber);
    end
    maxLength(ii) = max(lengths)
    minLength(ii) = min(lengths)
    meanLength(ii) = mean(lengths)
    medianLength(ii) = median(lengths)
    stdLength(ii) = std(lengths)
    histLengthFibers(ii,:) = histc(lengths,lengthRanges);
    save(fullfile(baseDir, 'adultsWholeBrainFibersStats.mat'), 'f', 'faThresh','nCoordsWM', 'nFibers', 'maxLength', 'minLength',...
        'meanLength', 'medianLength', 'stdLength', 'lengthRanges','histLengthFibers');
    clear fg lengths fibers mask roi wm x y z dt;
end
