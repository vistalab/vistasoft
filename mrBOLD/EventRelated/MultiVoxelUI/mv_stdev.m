function sigma = mv_stdev(mv, runs);
%
% sigma =  mv_stdev(mv, [runs]);
%
% Return a 2D matrix of format
% voxels x conditions containing
% estimated standard devation across trials,  evaluated 
% according to the 'ampType' parameter
% set in the params struct. Does not compute standard deviations
% for the null (0) condition.
%
% ras,  05/05.
if notDefined('mv'),    mv = get(gcf, 'UserData');  end

allRuns = unique(mv.trials.run);

if notDefined('runs'),    runs = allRuns;           end


% check that we have an amplitude type defined
if ~checkfields(mv, 'params', 'ampType')
    % set up a dialog,  get it
    ui.string = 'Method to Calculate Amplitudes?';
    ui.fieldName = 'ampType';
    ui.list = {'Peak-Bsl Difference',  'GLM Betas',  ...
        'Dot-product Relative Amps'};
    ui.style = 'popup';
    ui.value = ui.list{1};
    
    resp = generalDialog(ui, 'Select Amplitude Type');
    ampInd = cellfind(ui.list, resp.ampType);
    opts = {'difference' 'betas' 'relamps'};
    mv.params.ampType = opts{ampInd};
end

nConds = length(mv.trials.condNums)-1;

switch mv.params.ampType
    case {'difference', 'zscore'},    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % peak-bsl difference              %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % re-compute amplitudes for selected runs
        [tSeries, trials] = er_dataSubset(mv, runs);
        voxData = er_voxDataMatrix(tSeries, trials, mv.params);
        voxAmps = er_voxAmpsMatrix(voxData, mv.params);
        
        % compute standard deviation, robust to NaNs, and reshape
        sigma = permute( nanstd(voxAmps,[],1) , [2 3 1] );

    case 'betas',        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        % apply a GLM and get beta values  %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Get data from selected runs only
        [tSeries, trials] = er_dataSubset(mv, runs);
        
        % Build a design matrix,  apply the glm,  grab betas
        [X, nh, hrf] = glm_createDesMtx(trials,  mv.params,  tSeries,  0);
               

        model = glm(double(tSeries), X, mv.params.framePeriod, nh);       
        sigma = permute(model.stdevs(1,1:nConds,:), [3 2 1]);
        
    case 'relamps', 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        % dot-product relative amplitdues: %
        % * not currently implemented *    %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
        error('Sorry, not yet implemented')
        
    case 'deconvolved', 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Amplitudes of deconvolved time courses %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        error('Sorry, not yet implemented')

%         % Get data from selected runs only
%         [tSeries,  trials] = er_dataSubset(mv,  runs);
%         
%         % set up and run a GLM
%         params = mv.params;
%         params.glmHRF = 0;
%         TR = mv.params.framePeriod;
%         [X nh] = glm_createDesMtx(trials,  params,  tSeries);
%         model = glm(tSeries,  X,  TR,  nh);
%         
%         % get peak-bsl amplitudes from the deconvolved time courses
%         frameWindow = unique(round(mv.params.timeWindow./TR));
%         prestim = -1 * frameWindow(1);
%         peakFrames = unique(round(mv.params.peakPeriod./TR));
%         bslFrames = unique(round(mv.params.bslPeriod./TR));
%         peakFrames = find(ismember(frameWindow, peakFrames));
%         bslFrames = find(ismember(frameWindow, bslFrames));
% 
%         nConds = size(model.betas,  2);
% 
%         if mv.params.normBsl==1
%             offset = mean(model.betas(bslFrames, :, :),  1);
%             offset = repmat(offset,  [length(frameWindow) 1 1]);
%             model.betas = model.betas - offset;
%         end
% 
%         for i = 1:nConds
%             bsl = model.betas(bslFrames,  i,  :);
%             peak = model.betas(peakFrames,  i,  :);
%             sigma(:, i) = squeeze(nanmean(peak) - nanmean(bsl))';
%         end    

end


% return amplitudes for selected conditions only
sel = find(tc_selectedConds(mv));
sigma = sigma(:, sel-1);

return
% /----------------------------------------------------------------/ %





% /----------------------------------------------------------------/ %
function [subTSeries,  subTrials] = er_dataSubset(mv,  runs);
% Grab time series and trials (event-related design) data for the
% selected runs only from the mv struct.

allRuns = unique(mv.trials.run);

% Part 1: Need to find rows in tSeries 
% corresponding to the selected runs:
%
tr = mv.params.framePeriod;
nConds = sum(mv.trials.condNums>0);
nFrames = size(mv.tSeries, 1);

% first construct an index,  for each frame of the tSeries, 
% of the run that frame came from:        
runIndex = zeros(1, nFrames);

firstTrials = find(nVals(mv.trials.run)==1); 
firstFrames = mv.trials.onsetFrames(firstTrials);
runIndex(firstFrames) = mv.trials.run(firstTrials);    

% fill in each unassigned entry in the index
% with the current run (given in the previous entry):
I = intersect(firstFrames+1, 1:nFrames); % restrict to max # frames
while any(runIndex(I)==0)
    runIndex(I) = runIndex(I-1);
    I = intersect(I+1,  1:nFrames);
end

% now grab the appropriate rows from the tSeries:
ind = find(ismember(runIndex,  runs));
subTSeries = mv.tSeries(ind, :);

% part 2: get event onset/condition data
% for selected runs in subTrials struct: 
%
subTrials = mv.trials;
if ~isequal(runs, allRuns)
    % subTrials needs to reflect only selected runs,  
    % (tricky):

    % First,  find the # of frames in each run:
    lastTrials = [firstTrials(2:end)-1 length(mv.trials.onsetFrames)];
    lastTrialFrames = mv.trials.onsetFrames(lastTrials);
    framesPerRun = [lastTrialFrames(1) diff(lastTrialFrames)];

    % Next,  select event data only for selected subsets:
    ok = find(ismember(subTrials.run, runs));
    subTrials.onsetSecs = subTrials.onsetSecs(ok);
    subTrials.onsetFrames = subTrials.onsetFrames(ok);
    subTrials.cond = subTrials.cond(ok);
    subTrials.label = subTrials.label(ok);
    subTrials.run = subTrials.run(ok);
    subTrials.parfiles = subTrials.parfiles(runs);

    % Lastly,  correct the onset information: since onsets
    % are counted cumulatively,  they will reflect
    % non-selected runs. Correct for this overcounting:
    skippedRuns = setdiff(allRuns, runs);
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
