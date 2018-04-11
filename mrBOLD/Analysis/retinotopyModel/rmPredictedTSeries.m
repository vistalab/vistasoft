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
% rkl, 01/2018. Added the css version of the model.

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
viewType = viewGet(view, 'viewtype'); 

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
        % beta = beta([1 dcid+1]);
        beta = beta([1 dcid+1])';

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
        % replace nans with 0 so that the pinv code does not error out
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

        numCoords = size(coords,2);

        % recompute the fit
        recompFit = 0; 

        % % get variance explained
        % varexp = rmCoordsGet(viewType, model, 'varexp', coords);
        
        % % varexp of zero indicates that there is no pRF: all the params are 0. If
        % % we go through the code below, it will error (NaNs get introduced). Don't
        % % bother -- we know the return values are empty:
        % if varexp==0
        % 	nTimePoints = size(M.params.analysis.allstimimages, 1);
        % 	prediction  = zeros(nTimePoints, 1);
        % 	gridSize    = size(M.params.analysis.X(:), 1);
        % 	RFs         = zeros(gridSize, 1);
        % 	rfParams    = zeros(1, 6);
        %     blanks      = [];
        % 	return
        % end

        % rfParams 
        % get RF parameters from the model
        % rfParams = rmPlotGUI_getRFParams(model, modelName, viewType, coords, params)
        % rfParams = ff_rfParams(model, params, coords); % RLE function
        numCoords = size(coords,2); 

        rfParams = zeros(numCoords,8);
        rfParams(:,1) =  rmCoordsGet(viewType, model, 'x0', coords);        % x coordinate (in deg)        
        rfParams(:,2) =  rmCoordsGet(viewType, model, 'y0', coords);        % y coordinate (in deg)        
        rfParams(:,3) =  rmCoordsGet(viewType, model, 'sigmamajor',coords); % sigma (in deg)   
        rfParams(:,6) =  rmCoordsGet(viewType, model, 'sigmatheta',coords); % sigma theta (0 unless we have anisotropic Gaussians)
        rfParams(:,7) =  rmCoordsGet(viewType, model, 'exponent'  ,coords); % pRF exponent
        rfParams(:,8) =  rmCoordsGet(viewType, model, 'bcomp1',    coords); % gain ?                      
        rfParams(:,5) =  rfParams(:,3) ./ sqrt(rfParams(:,7));              % sigma adjusted by exponent 
  
        % RFs
        % RFs = rmPlotGUI_makeRFs(modelName, rfParams, params.analysis.X, params.analysis.Y);
        RFs = rfGaussian2d(params.analysis.X, params.analysis.Y, rfParams(:,3), rfParams(:,3), rfParams(:,6), rfParams(:,1), rfParams(:,2));

        % get/make trends
        [trends, ntrends, dcid] = rmMakeTrends(params, 0);

        % Compute final predicted time series (and get beta values)
        % we also add this to the rfParams, to report later.
        % we-do the prediction with stimulus that has not been convolved
        % with the hrf, and then add in the exponent, and then convolve

        % pred
        % make neural predictions for each RF
        % pred should be nFrames x numCoords
        % pred = (params.analysis.allstimimages_unconvolved * RFs) .^rfParams(:,7); % code for one voxel
        predFirstHalf = (params.analysis.allstimimages_unconvolved * RFs); 
        exponentVector = rfParams(:,7)'; 
        pred = bsxfun(@power, predFirstHalf, exponentVector); 
        pred(:, varexp == 0) = 0; 

        % reconvolve with hRF
        for scan = 1:length(params.stim)
            these_time_points = params.analysis.scan_number == scan;
            hrf = params.analysis.Hrf{scan};
            pred(these_time_points,:) = filter(hrf, 1, pred(these_time_points,:));
        end
        
        % betas
        beta = rmCoordsGet(viewType, model, 'b', coords);
        beta = beta(:,[1 dcid+1])';  % beta = beta([1 dcid+1])'; % original line
        
        % pred is a nFrames x numCoords matrix
        % beta is a 2 x numCoords matrix
        % the first column tells you how much to scale the tseries by
        % for each coord. the 2nd column tells you how much to add to
        % each point of the scaled time series
        predictionScale =  bsxfun(@times, pred, beta(1,:));
        predictionShift = trends(:,dcid) * beta(2,:); 
        prediction = predictionScale + predictionShift; 

        
        % update rfParams with beta
        % though actually it doesn't affect the predicted tseries anymore ...
        % rfParams is numCoords x 8 ... so fill in the 4th column with the first
        % row of beta
        % rfParams(4) = beta(1);  % original line. for 1 coord, beta is size 2 x 1
        rfParams(:,4) = beta(1,:)';

        % prediction -- DIFFERENT FOR RECOMPFIT PARAMETERS
        % prediction = [pred trends(:,dcid)] * beta;

        % convert
        % Convert to percent signal specified in the model, and we do not recompute
        % fit (if we recompute fit, the prediction will already be in % signal)
        if params.analysis.calcPC 
            % Only do this if the prediction is not already in % signal. We check
            % whether the signal is in % signal. If it is the mean should be
            % near-zero. So: 
            if abs(mean(prediction))>1 % random picked number (0.001 is too low)
                fprintf('[%s]:WARNING:converting prediction to %% signal even though recompFit=false.\n',mfilename);
                prediction  = raw2pc(prediction);
            end
        end
        
    otherwise,
        error('Unknown modelName: %s',modelName{modelId});
end;

return
%--------------------------------------