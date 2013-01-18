%% dti_STS_batchFindBorder.m
%
% Script for processing dti data from the STS_Project
% This batch script will take 2 ROIs, find that shared border between them,
% then create a new border ROI.
% (Batch script for the dtiFindBorderBetweenRois function - ER)
%
% HISTORY: AK wrote it (03/02/10). 
%
%% Set Directory Structure and Subject info

baseDir = '/biac3/wandell4/data/reading_longitude/';
dtiYr = {'dti_y1'};
subs =  {'ab0','ad0','ada0','ajs0','am0'};
dtDir = 'dti06trilinrt';

% Freesurfer labels - no extension
Label = {'1015', '1030'};

% Freesurfer Segmentation - no extension
seg = {'aparc_aseg'};
nodeName = 'border2015+2030node';


%%
%%************************************
% Do not edit below
%%************************************
for ii=1:numel(subs)

    for jj=1:numel(dtiYr)
        
        fprintf(1, 'Working on subject %s, year %s \n', subs{ii}, dtiYr{jj}); 

        sub = dir(fullfile(baseDir,dtiYr{jj},[subs{ii} '*']));
        if ~isempty(sub) % If there is no data for dtiYr{kk}, skip.
            subDir = fullfile(baseDir,dtiYr{jj},sub.name);
            dt6Dir = fullfile(subDir,dtDir);
            dt6File = fullfile(dt6Dir,'dt6.mat'); % Full path to dt6.mat
         
            roi1_img=fullfile(baseDir, 'freesurfer', sub.name, 'mri', [seg{1} Label{1} '.nii']);
            roi2_img=fullfile(baseDir, 'freesurfer', sub.name, 'mri', [seg{1} Label{2} '.nii']);
            borderRoiName='borderRoi1+Roi2';
            borderCoordsRoi=dtiFindBorderBetweenRois(roi1_img, roi2_img, dt6File, 7.5, borderRoiName);
            borderCoordsRoiFile=fullfile(baseDir, dtiYr{jj}, sub.name, dtDir, 'ROIs', ['border' Label{1} '+' Label{2}]);

            dtiWriteRoi(borderCoordsRoi, borderCoordsRoiFile);

        end
    end
end
