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
        
    case {'css','2D nonlinear pRF fit (x,y,sigma,exponent, positive only)'}
        % whether or not to recompute the prediction's fit
        % default is 1 so we just hardcode it
        % recompFit = 1; 
        viewType = viewGet(view, 'viewType');
        numCoords = size(coords, 2);
        numTimePoints = viewGet(view, 'nframes'); 
                
        % rfParams. direction from the function rmPlotGUI_getRFParams:
        % which just grabs one voxel's worth of informatio 
        rfParams(:,1) =  rmCoordsGet(viewType, model, 'x0', coords);        % x coordinate (in deg)        
        rfParams(:,2) =  rmCoordsGet(viewType, model, 'y0', coords);        % y coordinate (in deg)        
        rfParams(:,3) =  rmCoordsGet(viewType, model, 'sigmamajor',coords); % sigma (in deg)   
        rfParams(:,6) =  rmCoordsGet(viewType, model, 'sigmatheta',coords); % sigma theta (0 unless we have anisotropic Gaussians)
        rfParams(:,7) =  rmCoordsGet(viewType, model, 'exponent'  ,coords); % pRF exponent
        rfParams(:,8) =  rmCoordsGet(viewType, model, 'bcomp1',    coords); % gain ?                      
        rfParams(:,5) =  rfParams(3) / sqrt(rfParams(7));                   % sigma adjusted by exponent (not for calculations - just for diplay)

        % RFs. direction taken from rmPlotGUI_makeRFs
        RFs = rfGaussian2d(params.analysis.X, params.analysis.Y, rfParams(:,3), rfParams(:,3), rfParams(:,6), rfParams(:,1), rfParams(:,2));

        % we do the prediction with stimulus that has not been convolved
        % with the hrf, and then add in the exponent, and then convolve
        % make neural predictions for each RF
        % pred = (params.analysis.allstimimages_unconvolved * RFs).^rfParams(:,7);
        % versions earlier than Matlab 2016b don't support implicit
        % expansion of arrays with compatible sizes so here we expand the
        % above line: 
        exponentVector = rfParams(:,7)';       
        pred = bsxfun(@power, (params.analysis.allstimimages_unconvolved * RFs), exponentVector); 
                
        % get the time series so that we can get the betas
        % [tSeries, ~, ~] = rmLoadTSeries(view, params, coords, 1)
                
        % get the betas        
        % if recompFit
        %   beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
        %   beta(1) = max(beta(1),0);
        % else
        %    beta = rmCoordsGet(viewType, model, 'b', coords);
        %   beta = beta([1 dcid+1])';            
        %  end
        betaAll = rmCoordsGet(viewType, model, 'b', coords);
        beta1 = betaAll(:,1)'; 
        beta2 = betaAll(:,dcid+1)'; 
        
        % Calculate the prediction
        % the original line is a nice hack for one coord (though it doesn't
        % work for multiple coords).
        % For each voxel, it multiplies beta(1) to each point in the time
        % series and then adds corresponding trend * beta(2)
        % prediction = [pred trends(:,dcid)] * beta;
        prediction_part1 = bsxfun(@times, pred, beta1); 
        prediction_part2 = bsxfun(@plus, prediction_part1, beta2); 
        prediction = prediction_part1 + prediction_part2; 

        % Convert to percent signal specified in the model, and we do not recompute
        % fit (if we recompute fit, the prediction will already be in % signal)
        % if params.analysis.calcPC && ~recompFit
        %    % Only do this if the prediction is not already in % signal. We check
        %    % whether the signal is in % signal. If it is the mean should be
        %    % near-zero. So: 
        %    if abs(mean(prediction))>1 % random picked number (0.001 is too low)
        %        fprintf('[%s]:WARNING:converting prediction to %% signal even though recompFit=false.\n',mfilename);
        %        prediction  = raw2pc(prediction);
        %    end
        % end
        
        % recompute variance explained (do we need to do this?)
        % if recompFit==1
        %    rss = sum((M.tSeries(:,voxel)-prediction).^2);
        %    rawrss = sum(M.tSeries(:,voxel).^2);
        % else
        %    rss = rmCoordsGet(M.viewType, model, 'rss', coords);
        %    rawrss = rmCoordsGet(M.viewType, model, 'rawrss', coords);
        % end
        rss = rmCoordsGet(viewType, model, 'rss', coords);
        rawrss = rmCoordsGet(viewType, model, 'rawrss', coords);

        % sometimes rawss > rss. This can happen when the pRF is empty, and the
        % prediction is just the trend: the trend doesn't actually help always.
        % in this case, the varexp is zero, not negative:
        varexp = max(1 - rss./rawrss, 0);
        % varexp = 1 - rss ./ rawrss;
        
    otherwise,
        error('Unknown modelName: %s',modelName{modelId});
end;


return
%--------------------------------------


