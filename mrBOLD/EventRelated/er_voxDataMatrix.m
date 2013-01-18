function voxData = er_voxDataMatrix(tSeries,trials,params);
%
% voxData = er_voxDataMatrix(tSeries,trials,params);
%
% Given a 2D tSeries (scan time x voxels), return a
% 4D voxData matrix (trial time x trials x voxels x conditions).
% Use information from trials struct (loaded using 
% er_concatParfiles), and relevant event-related
% parameters (see er_loadParams).
%
%
% ras 04/05/05.
if nargin < 2
    help er_voxDataMatrix;
    return
end

if ieNotDefined('params')
    params = er_defaultParams;
end

% params
twFrames = params.timeWindow ./ trials.TR; % time window, in frames
twFrames = unique(floor(twFrames));
nonNull = trials.cond(trials.cond>0);
trialNum = nVals(nonNull); % trial # for each condition
nFrames = length(twFrames); % frames in a trial
nTrials = max(trialNum);
nVoxels = size(tSeries,2);
nConds = length(unique(nonNull));

% initalize matrix
% (Note that this will be permuted below)
voxData = repmat(NaN,[nFrames nVoxels nTrials nConds]);

% pad tSeries w/ NaNs before first trial and
% after last trial (to make grabbing data easier
% below):
preFrames = max(-1*min(twFrames),0); % frames before 1st trial
lastFrame = max(twFrames) + trials.onsetFrames(end);
postFrames = max(0,lastFrame-size(tSeries,1)+1); % frames after last trial

prestim = repmat(NaN,[preFrames nVoxels]);
poststim = repmat(NaN,[postFrames nVoxels]);

tSeries = [prestim; tSeries; poststim];

% get onsets of each non-null trial, in MR frames,
% adjusted for the padded NaN frames:
onsets = trials.onsetFrames(trials.cond>0);
onsets = onsets + preFrames;
onsets = onsets(onsets>preFrames);

% now loop through trials, grabbing the peri-
% stimulus time courses for each trial across
% voxels into the appropriate locations
% in voxel data:
for i = 1:length(onsets)
    trial = trialNum(i);
    cond = nonNull(i);
    tw = twFrames + onsets(i);
    voxData(:,:,trial,cond) = tSeries(tw,:);
end

% Now permute to format 
% trial time x trials x voxels x condition --
% I just find this a more sensible order:
voxData = permute(voxData,[1 3 2 4]);

return
