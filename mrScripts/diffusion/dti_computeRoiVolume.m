% dti_computeRoiVolume
%
% This script takes a group of ROIs and computes the Volume. Code adapted
% from dtiFiberUI (RFD).
%
% HISTORY:
% 05.14.2009 LMP wrote the thing.
%

%% directory structure
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_adults'};
logDir = fullfile(baseDir, 'dti_adults','ctr_controls','logs');
subs = {'aab050307','ah051003','am090121','ams051015','as050307','aw040809','ct060309','db061209','dl070825','dla050311',...
   'gd040901','gf050826','gm050308','jl040902','jm061209','jy060309','ka040923','mbs040503','me050126','mo061209',...
   'mod070307','mz040828','pp050208','rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};
% subs = {'bw040922'};

%% Start a text file 

dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logFile = fullfile(logDir,['roiVolume_',dateAndTime '.txt']);
fid=fopen(logFile,'w');
fprintf(fid, 'Subject \t ROI Name \t ROI Volume (mm^3)\t\n');

%%


rois = {'Mori_Occ_CC_100k_top1000_LEFT_ccRoi.mat'...
    'Mori_Occ_CC_100k_top1000_RIGHT_ccRoi.mat' ...
    'Mori_Occ_CC_100k_top10000_LEFT_ccRoi.mat' ...
    'Mori_Occ_CC_100k_top10000_RIGHT_ccRoi.mat'};

for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        subDir = fullfile(baseDir,yr{jj},sub.name);
        dt6 = fullfile(subDir,'dti06','dt6.mat');
        roiDir = fullfile(subDir,'dti06','ROIs','Mori_Contrack');

        disp(['Processing ' subDir '...']);

        t1 = niftiRead(fullfile(subDir,'t1','t1.nii.gz'));
        dt = dtiLoadDt6(dt6);
        s.subjectName = sub.name;
        [path s.imgName] = fileparts(t1.fname);

        for kk=1:length(rois)
            if exist(fullfile(roiDir,rois{kk})), disp('Roi found.');

            roi = dtiReadRoi(fullfile(roiDir,rois{kk}));
            s.roiName = roi.name;

            anat = double(t1.data);
            mmPerVoxel = t1.pixdim;
            xform = t1.qto_xyz;
            coords = roi.coords;

            ic = mrAnatXformCoords(inv(xform), coords);
            ic = unique(ceil(ic),'rows');
            sz = size(anat);
            imgIndices = sub2ind(sz(1:3), ic(:,1), ic(:,2), ic(:,3));
            n = length(imgIndices);
            volume = n*prod(mmPerVoxel);
            s.volume = sprintf('%0.2f mm^3', volume);
            
            fprintf(fid,'%s\t %s\t %d\t\n',sub.name,roi.name,volume);

            else disp([fullfile(roiDir,rois{kk}), ' does not exist']);
            end
        end
    end
end


disp('Done!');

