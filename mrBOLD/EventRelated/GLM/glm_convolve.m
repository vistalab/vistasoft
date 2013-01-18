function [X, hrf] = glm_convolve(trials, params, hrf, nFrames);
% [X, hrf] = glm_convolve(trials, params, [hrf], [nFrames]);
%
% Convolve a hemodynamic response function (HRF) with a set of 
% onset delta functions to create a contrast matrix.
%
% trials: a struct with onset and condition data (see er_concatParfiles).
%
% hrf: specify the hemodynamic impulse response function to use. Should
% always be in units of MR frames, starting with the first TR in which a
% stimulus was presented.
%
% nFrames: specify the total # of frames for each predictor
% in the design matrix. Default is to grab this from the last
% onset specified in trials.
%
% Returns a vector hrf which was used for convolution.
% 
% 07/04 ras. Based on parFile2DesMtx and desMtx2Predictors, 
% older code I wrote for the fMRA project.
% 09/04 ras: added nFrames arg.
% 09/10 amr, bw, and jw: changed convolution of HRF in design matrix so
% that runs don't overlap
if notDefined('hrf')
    hrf = glm_hrf(params);
end

if notDefined('nFrames')
    nFrames = trials.onsetFrames(end);
end

if ischar(hrf)      % name of a 'canned' HRF: get from glm_hrf
    params.glmHRF = hrf;
    hrf = glm_hrf(params);
end

% params
nConds = length(unique(trials.cond(trials.cond>0)));
nRuns = length(unique(trials.run));

% init design matrix
X = zeros(nFrames, nConds+nRuns);

% set up delta functions of onset frames for each condition
% (first nConds columns)
for i = 1:nConds
    ind = trials.onsetFrames(trials.cond==i) + params.onsetDelta;
    ind = ind(ind>0 & ind<nFrames);
    X(ind,i) = 1;
end

% if multiple trials are specified for each event (block-design),
% replicate the non-null trials the appropriate # of times
if isfield(params, 'eventsPerBlock') & max(params.eventsPerBlock) > 1
    % first, figure out how many times to replicate each onset:
    % For now, let's assume 'eventsPerBlock' directly specifies 
    % this number:
    duration = params.eventsPerBlock;
    while length(duration) < nConds
        duration(end+1) = duration(end);
    end
    
    for i = 1:nConds
        % get a duration for this condition
        nRep = duration(i);
        for j = find(X(:,i))' % for each onset in this column
            rng = j:j+nRep-1;
            rng = rng(rng>1 & rng<size(X,1));
            X(rng,i) = 1;
        end                        
    end
end

% Old code:
% convolve first nConds columns with hrf to make predictors
% for i = 1:nConds
%     tmp = conv2(X(:,i), hrf(:), 'full');
%     tmp = tmp(1:nFrames); % trim back to right length
%     X(:,i) = tmp;
% end

% New code:
% The convolution of the HRF should not extend beyond a run.  In the
% previous code, the runs were all stacked together and the convolution
% applied, which meant that predictions from one run were carried into the
% next run.  Here, we fixed this bug by separately applying the HRF to each
% run and then stacking them all together into the design matrix.
rowInds = 0;
for s = 1:nRuns
    rowInds = (1:trials.framesPerRun(s))+rowInds(end);
    tmp = conv2(X(rowInds,1:nConds), hrf(:), 'full');
    tmp = tmp(1:trials.framesPerRun(s),:); % trim back to right length
    X(rowInds,1:nConds) = tmp;
end
% figure; plot(X)

% the remaining nRuns columns are constant terms for each runs
% (1s during each run, 0 otherwise)
runNums = unique(trials.run);
for i = 1:nRuns
    run = runNums(i);
    whichTrials = find(trials.run==run); % trials in current run
    runStart = min(trials.onsetFrames(whichTrials));
    runEnd = max(trials.onsetFrames(whichTrials));
    rng = runStart:runEnd;
    rng = rng(ismember(rng,1:nFrames));
    X(rng,nConds+i) = 1; %/length(rng);
end


% % pad out: assign any remaining frames to last scan 
% X(rng(2)+1:end,end) = 1;

return
