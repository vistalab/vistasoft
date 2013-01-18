function [subTSeries, subTrials] = er_dataSubset(mv, runs);
% Grab time series and trials (event-related design) data for the
% selected runs only from the mv struct.
%
% [subTSeries, subTrials] = er_dataSubset(mv, runs);
%
% ras, 06/30/08. Originally written circa 2005, but I found it generally
% useful and broke it off from mv_amps.
allRuns = unique(mv.trials.run);

% Part 1: Need to find rows in tSeries 
% corresponding to the selected runs:
%
tr = mv.params.framePeriod;
nConds = sum(mv.trials.condNums>0);
nFrames = size(mv.tSeries,1);

% first construct an index, for each frame of the tSeries,
% of the run that frame came from:        
runIndex = zeros(1,nFrames);

firstTrials = find(nVals(mv.trials.run)==1); 
firstFrames = mv.trials.onsetFrames(firstTrials);
runIndex(firstFrames) = mv.trials.run(firstTrials);    

% fill in each unassigned entry in the index
% with the current run (given in the previous entry):
% NOTE: possible bug below: runIndex(I) = runIndex(I-1);
% this works if all runs have the same # of frames, but if 
% using some short runs, may overwrite prev runs. Need to
% subsample I to find runIndex(I)==0. I'm waiting to 
% correct this until I get time to thoroughly check it.
I = intersect(firstFrames+1,1:nFrames); % restrict to max # frames
while any(runIndex(I)==0)
    runIndex(I) = runIndex(I-1);
    I = intersect(I+1, 1:nFrames);
end

% now grab the appropriate rows from the tSeries:
ind = find(ismember(runIndex, runs));
subTSeries = mv.tSeries(ind,:);

% part 2: get event onset/condition data
% for selected runs in subTrials struct: 
%
subTrials = mv.trials;
if ~isequal(runs,allRuns)
    % subTrials needs to reflect only selected runs, 
    % (tricky):

    % First, find the # of frames in each run:
    lastTrials = [firstTrials(2:end)-1 length(mv.trials.onsetFrames)];
    lastTrialFrames = mv.trials.onsetFrames(lastTrials);
    framesPerRun = [lastTrialFrames(1) diff(lastTrialFrames)];

    % Next, select event data only for selected subsets:
    ok = find(ismember(subTrials.run,runs));
    subTrials.onsetSecs = subTrials.onsetSecs(ok);
    subTrials.onsetFrames = subTrials.onsetFrames(ok);
    subTrials.cond = subTrials.cond(ok);
    subTrials.label = subTrials.label(ok);
    subTrials.run = subTrials.run(ok);
    subTrials.parfiles = subTrials.parfiles(runs);

    % Lastly, correct the onset information: since onsets
    % are counted cumulatively, they will reflect
    % non-selected runs. Correct for this overcounting:
    skippedRuns = setdiff(allRuns,runs);
    for j = skippedRuns
        offset = framesPerRun(j);
        laterRuns = find(subTrials.run>j);
        subTrials.onsetFrames(laterRuns) = ...
            subTrials.onsetFrames(laterRuns) - offset;
        subTrials.onsetSecs(laterRuns) = ...
            subTrials.onsetSecs(laterRuns) - offset*tr;
    end
end


return