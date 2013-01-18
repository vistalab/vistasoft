function [prediction, RFs, rfParams, varexp] = rmPredictedTSeries(view, coords, modelId, params, allTimePoints)
% rmPredictedTSeries - Get predicted time series and receptive field for a view / coordinates.
%
% [prediction, RF] = rmPredictedTSeries(view, coords, [modelId], [params], [allTimePoints=1]);
% 
% INPUTS:
%   view: mrVista view. [defaults to cur view]
%   coords: coordinates from which to take data. For gray views, these 
%           are actually indices into view.coords. For inplane views,
%           these are 3xN (row, col, slice) coords relative to the inplane
%           anatomy.
%   modelId: index of retinotopy model to use. [Default: get from view.]
%   params: retinotopy model params. [Default: get from view.]
%   allTimePoints: flag indicating whether to predict all time points, or
%           a single cycle. If 1, will not average cycles. [Default 1.]
%
% OUTPUTS:
%   pred: predicted time series matrix (time points x voxels)
%   RF: predicted population receptive field matrix for each voxel
%       (visual field pixels x voxels).
% 
% ras, 12/2006. Broken off from rmPlot.
if ~exist('view','var') || isempty(view),      
    view = getCurView;                      
end
if ~exist('coords','var') || isempty(coords),   
    modelId = view.ROIs(view.currentROI).coords;  
end
if ~exist('modelId','var') || isempty(modelId),   
    modelId = viewGet(view, 'rmModelNum');  
end
if ~exist('allTimePoints','var') || isempty(allTimePoints),
    allTimePoints = false;              
end
if ~exist('params','var') || isempty(params),    
    params = viewGet(view, 'rmParams');
    params = rmRecomputeParams(view, params, allTimePoints);   
end

% Get model and info
model     = viewGet(view,'rmmodel');
model     = model{modelId};
modelName = rmGet(model, 'desc');

% get/make trends
verbose = false;
[trends,  ntrends, dcid] = rmMakeTrends(params, verbose);


% get variance explained
varexp = rmCoordsGet(view.viewType, model, 'varexp', coords);

% We plot the RF amplitude in peak HRF. But the HRFs are normalized to their
% volume (=1) so we need to multiply the amplitude (beta) estimates by the 
% HRF peak (params.analysis.HrfMaxResponse).
switch modelName,
    case '2D pRF fit (x,y,sigma, positive only)';
        % get RF parameters
        rfParams(:,1) = rmCoordsGet(view.viewType, model, 'x0', coords);
        rfParams(:,2) = rmCoordsGet(view.viewType, model, 'y0', coords);
        rfParams(:,3) = rmCoordsGet(view.viewType, model, 'sigmamajor',coords);

        % make RFs
        RFs = rfGaussian2d(params.analysis.X, params.analysis.Y, ...
            rfParams(:,3), rfParams(:,3), 0, rfParams(:,1), rfParams(:,2));

        % make predictions
        pred = params.analysis.allstimimages * RFs;

        % scalefactor
        beta = rmCoordsGet(view.viewType, model, 'b', coords);
        beta = beta([1 dcid+1]);

        prediction = [pred trends(:,dcid)] * beta;
        RFs        = RFs .* (beta(1) .* params.analysis.HrfMaxResponse);
        
        rfParams(:,4) = beta(1);

    case {'Double p2D RF fit (x,y,sigma,sigma2, center=positive)',...
            'Two independent 2D pRF fit (2*(x,y,sigma, positive only))'},
        % get RF parameters
        rfParams(:,1) = rmCoordsGet(view.viewType, model, 'x0', coords);
        rfParams(:,2) = rmCoordsGet(view.viewType, model, 'y0', coords);
        rfParams(:,3) = rmCoordsGet(view.viewType, model, 'sigmamajor',coords);

        % make RFs
        RFs = rfGaussian2d(params.analysis.X, params.analysis.Y, ...
            rfParams(:,3), rfParams(:,3), 0, rfParams(:,1), rfParams(:,2));

        % make predictions
        pred = params.analysis.allstimimages * RFs;

        % scalefactor
        beta = rmCoordsGet(view.viewType, model, 'b', coords);
        beta = beta([1 dcid+1]);

        prediction = [pred trends(:,dcid)] * beta;
        RFs        = RFs .* (beta .* params.analysis.HrfMaxResponse);



        [RFs, pred, RFs2, pred2, rfParams] = getrfsequence(view, params, model, coords);
        trendID     = trendID + 2;
        betaID      = getbetas(view, model, coords, trendID);
        for n = 1:size(coords,2),
            prediction1(:,n) = [pred(:,n) pred2(:,n) trends]*betaID(n,:)';
            prediction2(:,n) = [          pred2(:,n) trends]*betaID(n,2:end)';
            RFs(:,n)   = RFs(:,n).*(betaID(n,1).*params.analysis.HrfMaxResponse) +...
                RFs2(:,n).*(betaID(n,2).*params.analysis.HrfMaxResponse);

        end;

    otherwise,
        error('Unknown modelName: %s',modelName{modelId});
end;


return
%--------------------------------------


