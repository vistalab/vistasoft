function hrf = glm_hrf(params, tSeries, stim)
%
% hrf = glm_hrf(params, <tSeries>, <stim>);
%
% Returns the hemodynamic impulse response function to use for GLM
% analyses, given the current event analysis settings. The hrf will
% always be returned in units of MR frames.
%
% 'tSeries' and 'stim' are optional input arguments, which are only
% needed if params.glmHRF==1: compute the HRF from the data and
% selected conditions in params.snrConds.
%
% ras, 01/2007.
verbose = prefsVerboseCheck;

if ischar(params.glmHRF)
    hrfPath = fullfile(hrfDir, params.glmHRF);
    load(hrfPath, 'hrf', 'timeWindow', 'tr');
%     if verbose, fprintf('Loading HRF from file %s\n', hrfPath); end
    return
end

% for the pre-defined (Boynton, SPM, Dale&Buckner) HRFs, we'll need
% to get the time window sampled in units of MR frames, excluding pre-
% onset periods:
if ismember(params.glmHRF, [2 3 4])
    tr = params.framePeriod;
    maxT = max(params.timeWindow);          % in secs
    t = 0:tr:maxT;                          % also in secs
end

switch params.glmHRF
    case 1,
        % estimate hrf as mean time course to all stim
        if isempty(tSeries)
            errmsg = ['Need tSeries to estimate mean trial response ' ...
                '(glmHRF option 1)'];
            error(errmsg);
        end

%         if verbose, disp('Estimating mean trial response for GLM'); end
        tSeries = squeeze(mean(tSeries,2)); % mean across voxels
        anal = er_chopTSeries2(tSeries(:),stim,params);
        postStim = find(anal.timeWindow>=0);
        hrf = anal.meanTcs(postStim,anal.condNums>0);
        hrf = hrf(:,params.snrConds);
        if size(hrf,2) > 1
            hrf = nanmeanDims(hrf,2);
        end

    case 2,  % boynton gamma function
        % create sub-params struct
%         if verbose, disp('Boynton & Heeger gamma HRF'); end
        [p params] = glm_getHrfParams(params);
        n = params.glmHRF_params(1);
        tau = params.glmHRF_params(2);
        delay = params.glmHRF_params(3);
        hrf = boyntonHIRF(t, n, tau, delay);

    case 3,  % spm difference-of-gammas
%         if verbose, disp('SPM difference of gamma HRF'); end
        [p params] = glm_getHrfParams(params);
        hrf = spm_hrf(tr, p);

    case 4, % dale & buckner HRF
%         if verbose, disp('Dale and Buckner 2000 HRF: t^2*exp(-t)'); end
        [p params] = glm_getHrfParams(params);
        hrf = fmri_hemodyn(t, p(1), p(2));

    case 5, % saved HRF from file
        % choose from file
%         if verbose, disp('HRF selected from file \n'); end
        [f p] = myUiGetFile(hrfDir, '*.mat', 'Select a saved HRF File...');
        if f==0 % user canceled
            disp('User canceled -- setting HRF to Boynton Gamma')
            params.glmHRF = 2;
        else
            params.glmHRF = f(1:end-4);
        end
        hrf = glm_hrf(params);
        % TO DO: deal w/ situations in which the HRF was
        % saved using diff't TR, time window

    otherwise, error('Invalid specification for params.glmHRF.')
end

return



