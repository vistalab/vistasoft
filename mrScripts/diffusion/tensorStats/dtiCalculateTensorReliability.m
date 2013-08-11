function [wm_fa,wm_md,wm_pdd,wmProb]=dtiCalculateTensorReliability(subjectDir,figureDir)

% Usage: [wm_fa,wm_md,wm_pdd]=dtiCalculateTensorReliability(subjectDir,[figureDir=subjectDir],[wmProb])
% subjects = {'fullpath\subject'sDT6Dir'};
% figureDir = 'fullpath\to\directory\where\figures\will\be\saved';
% wmProb = a matrix variables with 0's wherever there is likely not wm, and
% 1's wherever there is likely wm. 
%
% This function will evaluate the reliability of the tensors for a subject.
% We want to make sure data quality is equivalent across subjects, and
% there are no between group differences, such that data is more reliable
% for adults vs kids (e.g., because kids might move more during the scan).
%
% To evaluate data reliability, we can take advantage of the maps created
% by dtiRawFitTensorMex. This is further described on vpnl and vista wikis
% http://vpnl.stanford.edu/internal/wiki/index.php/DTI_preprocessing#Evaluate_data_reliability
% http://white.stanford.edu/newlm/index.php/DTI#dtiRaw_pre-processing_pipeline
%
% The goal is to calculate the distribution of variances for FA, MD, and
% PDD in white matter. If data is reliable, stdev/dispersion of FA/MD/PDD
% estimates should be small and equivalent across subjects.
%
% Histogram figures will be created and saved.
%
% By DY 03/2008 with lots of help from Bob
% Modified 2008/07/16 to deal with new directory structure and also point
% to subjects dt6 dir rather than top-level subject directory. 
% Fixed by DY & RFD 2008/07/17 to better identify white matter voxels and
% pass out the mask (WMPROB) that results. 
%
% TODO: When comparing datasets, we want the intersection of two of the
% WMPROB from one dataset and the WMPROB from the other dataset so that
% there isn't bias towards one of the datasets 

% Change to subject's directory and get paths relative to this location
% for B0 and tensor niftis
cd(subjectDir) % this should actually be the subject's dt6dir
dt6struct=load('dt6.mat');
dt=dtiLoadDt6('dt6.mat');

% Create WMPROB, which consists of indices to only the voxels very likely
% to be white matter and excludes skull as much as possible.

% We used to use this line, but it doesn't work anymore for some reason.
%wmProb = dtiFindWhiteMatter(dt.dt6,[],dt.xformToAcpc);wmProb = wmProb>=0.9;

% Ideally, when comparing two datasets, what we want to do is calculate two
% independent masks, and take the intersection of these masks. 
[fa,md]=dtiComputeFA(dt.dt6);
wmProb = dt.brainMask & fa>.5 & md<1.1 & md>.6;
wmProb = dtiCleanImageMask(wmProb,0,0);

% Load variance niftis (fa, md, pdd)
% Since the dt6Dir may no longer be dti30 (even though it was dti30 when
% the directory was created), we take off the first part of the path in the
% dt6struct.files field. 
inds=strfind(dt6struct.files.faStd,'/'); inds=min(inds);
fa=niftiRead(dt6struct.files.faStd(inds+1:end));
inds=strfind(dt6struct.files.mdStd,'/'); inds=min(inds);
md=niftiRead(dt6struct.files.mdStd(inds+1:end));
inds=strfind(dt6struct.files.pddDisp,'/'); inds=min(inds);
pdd=niftiRead(dt6struct.files.pddDisp(inds+1:end));
wm_fa=fa.data(wmProb);
wm_md=md.data(wmProb);
wm_pdd=pdd.data(wmProb);

% This will create figures and save them to file.
% Can also save and show image as jpeg: saveas('jpg'), imshow('jpg')
% To view saved figures --> open('fig'): no need to call figure first

if(exist('figureDir','var'))
    if(~isdir('figureDir'))
        mkdir(figureDir)
    end
    cd(figureDir)
else
    figureDir=subjectDir;
end

figure; hist(wm_fa,30); h=gcf;
set(h,'name','Distribution of FA stds for voxels(wmProb>0.9)');
saveas(h,'fastd','fig');
figure; hist(wm_md,30); h=gcf;
set(h,'name','Distribution of MD stds for voxels(wmProb>0.9)');
saveas(h,'md','fig');
figure; hist(wm_pdd,30); h=gcf;
set(h,'name','Distribution of PDD dispersion for voxels(wmProb>0.9)');
saveas(h,'pdd','fig');

%     % Create mask ROI for all for all voxels in the map with probability
%     % greater than 0.9 (to infinity) and no smoothing
%     thresh = [0.9 inf];
%     smoothKernel = 0;
%     removeSatellites = 1;
%     roiName='mask_wmProb_90';
%     dt6=dtiLoadDt6(fullfile('dti30','dt6.mat'));
%     
%     % Mysterious values set with various GUI functions -- this is my best
%     % attempt to set them without the GUI
%     im=wmProb;
%     mm=dt6.mmPerVoxel;
%     mat=dt6.xformToAcpc;
%     
%     flags = {'fillHoles'};
%     if(removeSatellites) flags{end+1} = 'removeSatellites'; end
% 
%     newRoi = dtiNewRoi(roiName);
% 
%     % If voxels are not already 1x1x1 -- reslice
%     if(~all(mm==1))
%         [im,mat]=mrAnatResliceSpm(double(im),inv(mat),[],[1 1 1],[1 1 1 0 0 0],0);
%     end
%     
%     mask=im>=thresh(1) & im<thresh(2);
%     mask=dtiCleanImageMask(mask,smoothKernel,flags);
%     [x,y,z]=ind2sub(size(mask),find(mask));
%     newRoi.coords=mrAnatXformCoords(mat,[x,y,z]);
%     
%     % Write the Mask ROI (wmProb>0.9)
%     dtiWriteRoi(newRoi,[fullfile('dti30','ROIs', newRoi.name) '.mat']); 
