% dti_EVP_intersectFiberRois.m
%
% This simple script will load a group of fibers, create an ROI from those fibers,
% and intersect that ROI with another ROI, creating and saving a third ROI. 
%
% History:
% 2009.12.04 LMP wrote the thing.
%

%% Directory Structure
baseDir = '/biac3/wandell4/data/reading_longitude';
subs = {'aab050307','ah051003','am090121','ams051015','as050307','aw040809','bw040922','ct060309','db061209','dla050311'...
    'gd040901','gf050826','gm050308','jl040902','jm061209','jy060309','ka040923','mbs040503','me050126','mo061209',...
    'mod070307','mz040828','pp050208','rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};

yr = {'dti_adults'};
dirs = 'dti06';

rois1 = {'Mori_Occ_CC_100k_top1000_LEFT_ccRoi.mat'};
rois2 = {'Mori_Occ_CC_100k_top1000_RIGHT_ccRoi.mat'};


%% Start a text file 

dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logFile = fullfile(logDir,['roiVolume_1k_Occ_Intersection_',dateAndTime '.txt']);
fid=fopen(logFile,'w');
fprintf(fid, 'Subject \t ROI Name \t ROI Volume (mm^3)\t\n');

%% Work Loop
for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        if ~isempty(sub)
            subDir = fullfile(baseDir,yr{jj},sub.name);
            dt6Dir = fullfile(subDir, dirs);
            roiDir = fullfile(dt6Dir,'ROIs','Mori_Contrack');
            dt     = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));
            t1     = niftiRead(fullfile(subDir,'t1','t1.nii.gz'));

            disp(['Processing ' subDir '...']);
           
            % Load ROI and Fibers
            for kk=1:numel(roi1)
                
                roi1 = dtiReadRoi(fullfile(roiDir,rois1{kk}));
                roi2 = dtiReadRoi(fullfile(roiDir,rois2{kk}));
                intRoi = dtiIntersectROIs(roi1,roi2);
                intRoi.name = 'Mori_Occ_CC_100k_top1000_INTERSECTION_ccRoi.mat';
                intRoi.color = [.1 1.0 .1];
                
                dtiWriteRoi(intRoi,fullfile(roiDir,intRoi.name));
                v = dtiGetRoiVolume(intRoi,t1,dt);
                fprintf(fid,'%s\t %s\t %d\t\n',sub.name,intRoi.name,v.volume);
                
       
            end
        else disp(['No data for ' subs{ii} ' in ' yr{jj}]);
        end
    end
end
