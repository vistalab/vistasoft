function view = rmFinalFit(view,params)
% rmFinalFit - final fitting stage of retinotopic models
%
% view=rmFinalFit(view,params);
%
% Refit models at final stage to adjust for variance explained and beta values that may
% be off because they were (1) interpolated (2) not included in further
% fits.
% 
% Simpler form of rmRecomputeFit, that essentially calls rmSearchFit with 0
% iterations.
%
% 2009/03 SOD: wrote it.

if ~exist('params','var') || isempty(params),
    % See first if they are stored in the view struct
    params = viewGet(view,'rmParams');
    % if not loaded load them:
    if isempty(params),
        view = rmLoadParameters(view);
        params = viewGet(view,'rmParams');
    end;
    % but allow ROI definitions to change
    if view.selectedROI == 0,
        params.wData = 'all';
    else
        params.wData = 'roi';
    end;
end;

% Remove variance-explained threshold above which to do search.
params.analysis.fmins.vethresh = 0;

% Set iterations to 0
params.analysis.fmins.options = optimset(params.analysis.fmins.options,'MaxIter',0);

% recall rmSearchFit
view = rmSearchFit(view,params);

return

