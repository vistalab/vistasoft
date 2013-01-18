% this script creates a wm mask using different thresholds: 0.2 -0.8, saves
% nCoordsWM for each threshold, for each subject
% updated: 20050530
%baseDir = '//snarp/u1/data/reading_longitude/dti_adults';%on teal
%baseDir = 'U:\data\reading_longitude\dti_adults';% on cyan
% baseDir = 'U:\data\reading_longitude\dti';% kids, on cyan
baseDir = '//snarp/u1/data/reading_longitude/dti'; % for kids, on teal

%f = {'ab050307','as050307','aw040809','bw040806','bw040922','gm050308',...
%         'jl040902','ka040923','mbs040503','mbs040908','me050126','mz040604','mz040828',...
%         'pp050208','pp050228','rd040630','sn040831','sp050303'};% 14 subjects 6 directions only (add rd040901?). run again for 23?
%f = {'mbs040503'}; %for debug
f = findSubjects('','',{'tk040817','sl050516','dh050513','pf050514','mh050514','rh050514','mho050528', 'ctr050528','clr050528'});%excluding tk and 2005 subjects
faThresh = [0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8];
nCoordsWM = zeros(length(f),length(faThresh));
volumeWM = zeros(length(f),length(faThresh));

for(ii=1:length(f))
    fname = f{ii}; %for kids when using findsubjects
    %fname = fullfile(baseDir, f{ii}, [f{ii} '_dt6_acpc_2x2x2mm.mat']);
    disp(['Processing ' fname '...']);
    dt = load(fname);
    dt.dt6(isnan(dt.dt6)) = 0;
    dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
    fa = dtiComputeFA(dt.dt6);

    %create a white matter mask
    for(jj = 1:length(faThresh)) 
        roi = dtiNewRoi('wm');
        mask = fa>=faThresh(jj);
        [x,y,z] = ind2sub(size(mask), find(mask));
        roi.coords = dtiXformCoords(dt.xformToAcPc, [x,y,z]);
        roi = dtiRoiClean(roi, 3, {'removeSat'});% don't fill holes for this purpose
        %save(fullfile(roiPath, roi.name), 'roi');
        wm = roi;
        nCoordsWM(ii,jj) = size(wm.coords,1);
        % we get volume by multiplying by 8, assuming dti voxel size 2x2x2
        % (this is how its done in dtiGetRoiStats too)
        volumeWM(ii,jj) = size(wm.coords,1)*8;
        clear wm;
    end
    save(fullfile(baseDir, 'childWMmaskStats050530.mat'), 'f', 'nCoordsWM', 'volumeWM');    
end

