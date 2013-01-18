function [X, nh, hrf] = glm_createDesMtx(stim, params, tSeries, reshapeFlag)
% Create a design matrix appropriate for the hrf option
%
% [X, nh, hrf] = glm_createDesMtx(stim, [params], [tSeries or nFrames], [reshapeFlag]);
%
% Create a design matrix appropriate for the hrf option specified in the
% selected event-related params (see er_getParams for more info on the
% params struct).
%
% If the params.glmHRF option is 0, the design matrix X will be appropriate
% for a deconvolution GLM in which time courses relative to trial onset for
% each condition are estimated as part of the GLM. If this flag is positive
% (1-3), a design matrix X will be returned in which there is a single
% predictor function for each condition, using an assumed form of the
% hemodynamic response function (HRF).
%
% Entering the optional tSeries argument is needed if the params.glmHRF
% option is 1 -- estimate HRF from mean response to all stim. If entered,
% the design matrix will also be clipped to the # of frames in the tSeries.
% You can enter the # of frames directly as the third argument instead of
% the whole tSeries if you are using a different HRF option, but want to
% clip to the # of frames.
%
% The optional reshape flag, if set to 1 [default 0], will cause the
% otherwise-2D matrix to be set as a 3D matrix with the third dimension
% being different scans. This is appropriate for much of the new GLM code.
%
% Also returns nh, the # of time points to use in the hemodynamic response
% window for estimating a GLM. (see glm, applyGlm); and hrf, the response
% function used (empty if deconvolving).
%
%
% ras, 04/05
% ras, 03/06: divides each predictor column by the max absolute value
% of that column, so they range between -1 and 1 (but 0 values are 
% unchanged). We may want to set a parameter for this (in which case, it should
% logically go into params, like 'params.glmNormalize', but I'm 
% confident enough that this is the right move that I'm going to 
% not make it do this). -ras, 03/01/01
%
% TODO:
%   We need to properly insert the dmNorm flag ... right now it is just a
%   place holder.  We think we should make options for 'spm', 'unitPeak'
%   and 'unitAmp'.
%
if notDefined('params'),      params = er_defaultParams;  end
if notDefined('reshapeFlag'), reshapeFlag = 0;            end
if notDefined('tSeries'),     tSeries = [];               end
if notDefined('dmNorm'),      dmNorm = 'unitPeak';        end

tr = params.framePeriod;

if ~isfield(params, 'rmTrend'), params.rmTrend = 0;       end

% figure out whether an entire tSeries was passed, or just a # of frames:
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

% decide whether we're deconvolving (getting estimated time courses 
% for each condition) or fitting an HIRF (getting only a single beta value
% for each condition) based on the selected event-related hrf parameter. 
% Get a corresponding stimulus matrix:
if params.glmHRF==-1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % just return the delta functions %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    nF = max(stim.framesPerRun);
    X = delta_function_from_parfile(stim.parfiles, tr, nF);  
    X = permute(X, [1 3 2]);    % reshape to be 2D frames x conditions
    X = reshape(X, [size(X,1)*size(X,2) size(X,3)]);    
    if (size(X,1) < nFrames), X(nFrames,end) = 0; end
    X = X(1:nFrames,:);
    nh = 1;
    hrf = [];
    
elseif params.glmHRF==0
    %%%%%%%%%%%%%%%%
    % deconvolving %
    %%%%%%%%%%%%%%%%
    framesPerScan = max(stim.framesPerRun);
    
    % make a delta-function matrix for onsets of 
    % different conditions:
    s = delta_function_from_parfile(stim.parfiles, tr, framesPerScan);
    
    % create Toeplitz matrix for estimating deconvolved responses
    % (see papers on 'selective-averaging', e.g. by Randy Buckner
    % or Douglas Greve for the Freesurfer code)
    fw = unique(round(params.timeWindow/tr)); % time window in frames (TRs)
    hrf = [];
    % nConds =  size(s,2); 
    [X nh] = glm_deconvolution_matrix(s, fw);
    
    % also add a 'trend-removal' component, to mirror the trend removal
    % in the FS-FAST processing stream (see fast_trendmtx):
    if params.rmTrend==1
        nScans = length(stim.parfiles);
        Xtrend = zeros(framesPerScan, nScans, nScans);
        for i = 1:nScans
            v = (0:framesPerScan-1)'; 
            v = v - mean(v);
            v = v./sqrt(sum(v.^2));
            Xtrend(:,i,i) = v;
        end
        X = cat(2, X, Xtrend);
    end

    % reshape to 2D (will undo later if needed)
    X = reshape(permute(X,[1 3 2]),[size(X,1)*size(X,3) size(X,2)]);
else
    %%%%%%%%%%%%%%%%
    % applying HRF %
    %%%%%%%%%%%%%%%%
    % first, construct the impulse response function: 
    if params.glmHRF==1         % estimate from SNR conds
        hrf = glm_hrf(params, tSeries, stim);
    else                        % use preset HRF
        hrf = glm_hrf(params);
    end
    
    % apply HRF -- return a 2D matrix covering whole time course
    % (at this point, the HRF is in units of MR frames, not seconds)
    [X, hrf] = glm_convolve(stim, params, hrf, nFrames);    
    
    % we're only returning one predictor per condition: the
    % nh variable should note this:
    nh = 1;
end

% The design matrix normalization can be specified by dmNorm.  This is not
% yet implemented mainly.  Rory used unit peak all the time.  
% The comment below suggests that unit peak implies that beta has the same
% units as the time series. I am not sure that is true (BW). 
switch lower(dmNorm)
    case 'unitpeak'
        % Norm axes of each column, such that the max positive value is 1,
        % or the max negative value is -1, but 0 values remain 0.
        % This will ensure that beta values reflect the units of the input
        % data (time series).
        for i = 1:size(X, 2)
            X(:,i) = X(:,i) ./ max(abs(X(:,i)));
        end
    case 'unitamp'
        disp('Not yet implemented')
    case 'spm'
        disp('Not yet implemented')
    otherwise
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
    nScans = length(framesPerRun);
    nPredictors = size(X,2);
    
    % init 3D X matrix
    oldX = X;
    X = zeros(maxFrames,nPredictors,nScans);
    
    % reshape (allow for different-length runs)
    for run = 1:nScans
        rng = onsets{run}(1):onsets{run}(end);
        X(1:framesPerRun(run),:,run) = oldX(rng,:);
    end
end



return


