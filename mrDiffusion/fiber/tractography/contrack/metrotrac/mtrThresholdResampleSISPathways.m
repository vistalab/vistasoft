function mtrThresholdResampleSISPathways(fgFilenames,samplerOptsFilename,weightThreshold,dt6Filename,fgResampledFilename,bCalcStats)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% mtrThresholdResampleSISPathways(fgFilenames,samplerOptsFilename,
%%                                numSamplesPerCluster,clusterROI,
%%                                fgResampledFilename)
%%
%% fgFilenames - filenames for metrotrac pathways
%% samplerOptsFilename - parameters file for collecting paths and stats
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

% Get importance weight file that we need to resample with also load the
% pathfile into matlab
totalFiberCount = 1;
fg_input = dtiNewFiberGroup;
fg_temp = dtiNewFiberGroup;

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

    % Keep aggregating all of the fibers together into one group
    if(isempty(fg_input.fibers))
        fg_input.fibers = fg_temp.fibers;
    else
        fg_input.fibers = [fg_input.fibers(:), fg_temp.fibers(:)];
    end
     toc;
end
clear fg_temp;

% Send the valid matrix in with the resample computations
[fg_output, sample_w] = resampleThresholdSISPathways(weightThreshold, statvec_names, fg_input);

% Output the pathways in dtifiberUI space
%dtiWriteFiberGroup(fg_output,fgResampledFilename);

% Output the pathways in metrotrac space
mtrExportFiberGroupToMetrotrac(fgResampledFilename,fg_output,dt6.t1NormParams,dt6.mmPerVox,dt6.xformToAcPc,size(dt6.b0));

% Cleanup temp files
delete('temp.dat');

% Why should I delete these stats?? they are yummy!!
% for ii = 1:length(statvec_names)
%     delete(statvec_names{ii});
% end

return;

function [fg_output, sample_w_out] = resampleThresholdSISPathways(weightThreshold, weightFilenames, fg_input)

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
% Now just threshold the paths based on weightThreshold
iwThresholded = find(iw > weightThreshold);

% Get the paths that survive the threshold
fg_output.fibers = fg_input.fibers(iwThresholded);
sample_w_out = ones(size(fg_output.fibers));

return;