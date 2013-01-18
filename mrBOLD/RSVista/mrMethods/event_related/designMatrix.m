function [X, nh, hrf] = designMatrix(stim,params,tSeries,reshapeFlag);
%
% Create a design matrix appropriate for the hrf option
% specified in the selected event-related params 
% (see eventParamsDefault for more info on the params struct).
%
% Usage:
% [X, nh, hrf] = designMatrix(stim, [params], [tSeries or nFrames], ...
%                                   [reshapeFlag]);
%
%
% If the params.glmHRF option is 0, the design matrix X will
% be appropriate for a deconvolution GLM in which time 
% courses relative to trial onset for each condition are 
% estimated as part of the GLM. If this flag is positive (1-3),
% a design matrix X will be returned in which there is a single
% predictor function for each condition, using an assumed form
% of the hemodynamic response function (HRF).
%
% Entering the optional tSeries argument is needed if the
% params.glmHRF option is 1 -- estimate HRF from mean 
% response to all stim. If entered, the design matrix
% will also be clipped to the # of frames in the tSeries.
% You can enter the # of frames directly as the third 
% argument instead of the whole tSeries if you are using
% a different HRF option, but want to clip to the # of frames.
%
% The optional reshape flag, if set to 1 [default 0], will 
% cause the otherwise-2D matrix to be set as a 3D matrix
% with the third dimension being different scans. This is 
% appropriate for much of the new GLM code.
%
% Also returns nh, the # of time points to use in the 
% hemodynamic response window for estimating a GLM.
% (see glm, applyGlm); and hrf, the response function
% used (empty if deconvolving).
%
%
% ras, 04/05
% ras, 08/05 -- imported into mrVista 2.0.
if notDefined('params'),      params = eventParamsDefault;    end
if notDefined('reshapeFlag'), reshapeFlag = 0;                end
if notDefined('tSeries'),     tSeries = [];                   end

tr = params.framePeriod;

% figure out whether an entire tSeries
% was passed, or just a # of frames:
if length(tSeries)==1
    % nFrames is specified, rather than tSeries
    nFrames = tSeries;
    tSeries = [];
elseif ~isempty(tSeries)
   nFrames = size(tSeries,1);
   if nFrames==1
       % need it as a column vector
       tSeries = tSeries';
       nFrames = size(tSeries,1);
   end
end

if isempty(tSeries)
	% default is max frames specified in stim struct
    nFrames = stim.onsetFrames(end);
end

% decide whether we're deconvolving (getting 
% estimated time courses for each condition)
% or fitting an HIRF (getting only a single beta value
% for each condition) based on the selected event-related
% hrf parameter. Get a corresponding stimulus matrix:
if params.glmHRF==0
    framesPerScan = max(stim.framesPerRun);
    
    % make a delta-function matrix for onsets of 
    % different conditions:
    s = delta_function_from_parfile(stim.parfiles,tr,framesPerScan);
    
    % create Toeplitz matrix for estimating deconvolved responses
    % (see papers on 'selective-averaging', e.g. by Randy Buckner
    % or Douglas Greve for the Freesurfer code)
    fw = unique(round(params.timeWindow/tr)); % time window
    hrf = [];
    nConds =  size(s,2); 
    [X nh] = eventDeconvolutionMatrix(s,fw);
    
    % reshape to 2D (will undo later if needed)
    X = reshape(permute(X,[1 3 2]),[size(X,1)*size(X,3) size(X,2)]);
else
    % apply HRF -- first, construct the impulse response function:
    switch params.glmHRF
        case 1, 
            % estimate hrf as mean time course to all stim
            if isempty(tSeries)
                errmsg = 'Need tSeries to estimate mean trial response (glmHRF option 1)';
                error(errmsg);
            end
            
            disp('Estimating mean trial response for GLM')
            tSeries = squeeze(mean(tSeries,2)); % mean across voxels
            anal = eventTimeCourses(tSeries(:),stim,params);
            postStim = find(anal.timeWindow>=0);
            hrf = anal.meanTcs(postStim,anal.condNums>0);
            hrf = hrf(:,params.snrConds);
            if size(hrf,2) > 1
                hrf = nanmeanDims(hrf,2);
            end
            hrf = hrf ./ sum(hrf); % normalize to integral 1
        case 2,  % boynton gamma function
            hrf = 'boynton';
        case 3,  % spm difference-of-gammas
            hrf = 'spm';
        case 4, % dale & buckner HRF
            hrf = 'dale';
    end
    
    % apply HRF -- return a 2D matrix covering whole time course
    [X, hrf] = eventConvolveHRF(stim,params,hrf,nFrames);            
    
    % we're only returning one predictor per condition: the
    % nh variable should note this:
    nh = 1;
end

if reshapeFlag==1
    % return a 3D matrix w/ runs as the 3rd dimension
    
    % figure out max # frames per run to 
    % use for reshaping
    for run = unique(stim.run)
        ind = find(stim.run==run);
        onsets{run} = stim.onsetFrames(ind);
        framesPerRun(run) = onsets{run}(end)-onsets{run}(1)+1;
    end
    maxFrames = max(framesPerRun);
    nRuns = length(framesPerRun);
    nPredictors = size(X,2);
    
    % init 3D X matrix
    oldX = X;
    X = zeros(maxFrames,nPredictors,nRuns);
    
    % reshape (allow for different-length runs)
    for run = 1:nRuns
        rng = onsets{run}(1):onsets{run}(end);
        X(1:framesPerRun(run),:,run) = oldX(rng,:);
    end
end



return
