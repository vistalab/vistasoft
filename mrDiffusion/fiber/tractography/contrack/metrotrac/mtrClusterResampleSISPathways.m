function mtrClusterResampleSISPathways(fgFilenames,samplerOptsFilename,numSamplesPerCluster,clusterROIFilename,dt6Filename,fgResampledFilename, hintNumTotalFibers, bCalcStats)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% mtrClusterResampleSISPathways(fgFilenames,samplerOptsFilename,
%%                                numSamplesPerCluster,clusterROI,
%%                                fgResampledFilename)
%%
%% fgFilenames - filenames for metrotrac pathways
%% samplerOptsFilename - parameters file for collecting paths and stats
%% numSamplesPerCluster - total weight of all resamples
%% clusterROIFilename - ROI where we will resample pathways around each coordinate
%%              of the ROI.
%% fgResampledFilename - filename for resampled pathways
%% dt6Filename - Filename for dt6.
%% hintNumTotalFibers - Number hopefully greater than the total number of
%% fibers that we will load.  This will speed up processing significantly
%% as it will allow us to preallocate space for validity matrix.
%% bCalcStats - True then calculate the statistics False then they already
%% exist.
%%
%%
%% Author: Anthony Sherbondy
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Constants
DISTANCE_THRESH = 2;


%% MUST MAKE SURE THIS PROGRAM IS COMPILED AND IN RIGHT LOCATION
if(ispc)
    executable = which('updatestats.exe');
else
    error('Not compiled for Linux.');
end

% Get all the needed files
if(ieNotDefined('dt6Filename'))
    [f, p] = uigetfile({'*.mat';'*.*'}, 'Load DT6 file...');
    if(isnumeric(f)), disp('Resampling canceled.'); return; end
    dt6Filename = fullfile(p,f);
end

dt6 = load(dt6Filename);

% Load ROI
roi = load(clusterROIFilename);
roi = roi.roi;

% Get importance weight file that we need to resample with also load the
% pathfile into matlab
totalFiberCount = 1;
fg_input = dtiNewFiberGroup;
fg_temp = dtiNewFiberGroup;

% Allocate validity map with hint of number of total fibers
if(ieNotDefined('hintNumTotalFibers'))
    hinNumTotalFibers = 50000;
end
validFiberToROIMap = logical(zeros(size(roi.coords,1),hintNumTotalFibers));

for ii = 1:length(fgFilenames)
     tic;
    statvec_names{ii} = sprintf('temp%d_statvec_iw.dat',ii);
    if(bCalcStats)
        disp('Calculating Statistics.');
        args = sprintf(' -v %s -i %s -o temp.dat -s 4 -sf %s', samplerOptsFilename, fgFilenames{ii}, statvec_names{ii});
        cmd = [executable args];
        disp(cmd); disp('...')
        [s, ret_info] = system(cmd,'-echo');
        disp('Done.')
    end

    disp('Loading pathway file into matlab...')
    fg_temp = mtrImportFibers(fgFilenames{ii}, dt6.xformToAcPc);
    disp('Done')
    
    % For all of the ROI points see which pathways are close enough
    disp('Finding closest ROI points for each path...')

    for ff = 1:length(fg_temp.fibers)
        [indices, bestSqDist] = nearpoints(roi.coords', fg_temp.fibers{ff});
        % Coordinates are in mm
        validFiberToROIMap(:,totalFiberCount) = bestSqDist < DISTANCE_THRESH;
        totalFiberCount = totalFiberCount+1;
    end
    disp('Done')

    % Keep aggregating all of the fibers together into one group
    if(isempty(fg_input.fibers))
        fg_input.fibers = fg_temp.fibers;
    else
        fg_input.fibers = {fg_input.fibers{:}, fg_temp.fibers{:}};
    end
     toc;
end
clear fg_temp;

% Send the valid matrix in with the resample computations
[fg_output, sample_w] = resampleClusterSISPathways(numSamplesPerCluster, statvec_names, fg_input, roi, validFiberToROIMap);

% Output the pathways in dtifiberUI space
dtiWriteFiberGroup(fg_output,fgResampledFilename);

% Output the pathways in metrotrac space
%mtrExportFiberGroupToMetrotrac(fgResampledFilename,fg_output,dt6.t1NormParams,dt6.mmPerVox,dt6.xformToAcPc,size(dt6.b0));

% Cleanup temp files
delete('temp.dat');

% Why should I delete these stats?? they are yummy!!
% for ii = 1:length(statvec_names)
%     delete(statvec_names{ii});
% end

return;

function [fg_output, sample_w_out] = resampleClusterSISPathways(numSamplesPerCluster, weightFilenames, fg_input, roi, validFiberToROIMap)

numFiles = length(weightFilenames);
sizeFiles = [];

% Setup the output file
fg_output = dtiNewFiberGroup;

% Load multiple importance weight files
iw = [];
for f = 1:numFiles
    iwtemp = mtrLoadStatvec(weightFilenames{f});
    iw = [iw; iwtemp];
    sizeFiles(f) = length(iwtemp);
end
% Give everything a small chance of sampling
iw = exp(iw)+realmin;

% For each ROI point lets resample from the database
for rr = 1:size(roi.coords,1)
    iwROI = validFiberToROIMap(rr,:) .* iw(:)';
    % If no fibers are near enough to this position forget about it
    if(sum(iwROI)>0)
        % Resample pathways according to normalized weight and whether they are
        % near this ROI point
        sample_ind = randsample([1:length(iwROI)],numSamplesPerCluster,true,iwROI);
        unique_sample_ind = unique(sample_ind);
        unique_sample_w = 0;
        for i = 1:length(unique_sample_ind)
            unique_sample_w(i) =  sum(sample_ind == unique_sample_ind(i));
        end
        % Add fibers sampled from this ROI to the output fiber group
        if(isempty(fg_output.fibers))
            fg_output.fibers = {fg_input.fibers{unique_sample_ind}};
            sample_w_out = unique_sample_w;
        else
            fg_output.fibers = {fg_output.fibers{:}, fg_input.fibers{unique_sample_ind}};
            sample_w_out = [sample_w_out, unique_sample_w];
        end
    else
    end
end

return;