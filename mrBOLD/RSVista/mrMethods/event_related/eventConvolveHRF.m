function [X, hrf] = eventConvolveHRF(trials,params,hrf,nFrames);
% [X, hrf] = eventConvolveHRF(trials,params,[hrf],[nFrames]);
%
% Convolve a hemodynamic response function (HRF) with a set of 
% onset delta functions to create a contrast matrix.
%
% trials: a struct with onset and condition data (see er_concatParfiles).
%
% hrf: specify the hemodynamic impulse response function to use. Can be a 
% vector with a custom hrf (e.g., the mean response for the subject
% estimated from the data), or can be a flag for a pre-specified hrf.
% Current options for the latter are 'boynton' [default], taken from
% boynton et al., 1999 (gamma function), and 'spm', the default 
% HIRF used by SPM (difference-of-gammas, includes a significant
% undershoot).
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
% 08/05 ras: imported into mrVista 2.0.
if ieNotDefined('hrf')
    hrf = 'boynton';
end

if ieNotDefined('nFrames')
    nFrames = trials.onsetFrames(end);
end

% parse the hrf (if not explicitly entered as a vector)
if ischar(hrf)
    postStim = params.timeWindow(params.timeWindow>=0);
    t = postStim(unique(round(postStim./trials.TR))+1);
    switch lower(hrf)
        case 'boynton', 
            % fprintf('Using boyntonHIRF to generate predictors...\n');
            [hrf,t,params] = boyntonHIRF(t);
            hrf = hrf';
        case 'heeger',
            hrf = heeger_hrf(t);
            hrf = hrf';
        case 'spm', 
            % fprintf('Using spm_hrf to generate predictors...\n');
            hrf = spm_hrf(trials.TR);
        case {'dale','buckner'},
            hrf = DaleBucknerHIRF(t,1.25,2.5); 
            % normalize to have an integral of 1
            % for trial count to work:
            hrf = hrf ./ sum(hrf);
        otherwise, error([hrf ' is not a valid hrf specification.']);
    end
end

% params
nConds = length(unique(trials.cond(trials.cond>0)));
nRuns = length(unique(trials.run));

% init design matrix
X = zeros(nFrames,nConds+nRuns);

% set up delta functions of onset frames for each condition
% (first nConds columns)
for i = 1:nConds
    ind = trials.onsetFrames(trials.cond==i);
    ind = ind(ind>0 & ind<nFrames);
    X(ind,i) = 1/length(ind);
end

% convolve first nConds columns with hrf to make predictors
for i = 1:nConds
    tmp = conv2(X(:,i),hrf,'full');
    tmp = tmp(1:nFrames); % trim back to right length
    X(:,i) = tmp;
end

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
