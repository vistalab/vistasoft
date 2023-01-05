function [prediction rfParams] = rmPlotGUI_scaleFactor(M, pred, rfParams, recompFit);
%
%
%
%
% ras, 11/2008.
model     = M.model{M.modelNum};
modelName = rmGet(model, 'desc');
voxel     = get(M.ui.voxel.sliderHandle, 'Value');
coords	  = M.coords(:,voxel);
if isequal(M.viewType, 'Gray')  % convert coords into an index
    coords = M.coords(voxel);
end

%% get/make trends
[trends, ntrends, dcid] = rmMakeTrends(M.params, 0);
if isfield(M.params.analysis,'allnuisance')
    trends = [trends M.params.analysis.allnuisance];
end

%% Compute prediction; compute beta scale factors according to the model
% we also add this to the rfParams, to report later
switch modelName,
    case {'2D pRF fit (x,y,sigma, positive only)',...
            '2D RF (x,y,sigma) fit (positive only)'};
        if recompFit==0,
            beta = rmCoordsGet(M.viewType, model, 'b', coords);
            beta = beta([1 dcid+1]);
        else
            beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
            beta(1) = max(beta(1),0);
            
            % also recompute variance explained
            prediction = [pred trends(:,dcid)] * beta;
            prediction = prediction(:,1);
        end

        prediction = [pred trends(:,dcid)] * beta;
        RFs        = RFs .* (beta(1) .* M.params.analysis.HrfMaxResponse);

        rfParams(4) = beta(1);

    case {'2D pRF fit (x,y,sigma_major,sigma_minor)' ...
			'oval 2D pRF fit (x,y,sigma_major,sigma_minor,theta)'};
        if recompFit==0,
            beta = rmCoordsGet(M.viewType, model, 'b', coords);
            beta = beta([1 dcid+1]);
        else
            beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
            beta(1) = max(beta(1),0);
            
            % also recomput variance explained
            prediction = [pred trends(:,dcid)] * beta;
            prediction = prediction(:,1);
            rss = sum((M.tSeries(:,voxel)-prediction).^2);
            rawrss = sum(M.tSeries(:,voxel).^2);
            varexp = 1 - rss./rawrss;
        end

        prediction = [pred trends(:,dcid)] * beta;
        RFs        = RFs .* (beta(1) .* M.params.analysis.HrfMaxResponse);

        rfParams(4) = beta(1);

    case 'unsigned 2D pRF fit (x,y,sigma)';
        if recompFit==0,
            beta = rmCoordsGet(M.viewType, model, 'b', coords);
            beta = beta([1 dcid+1]);
        else
            beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
            
            % also recomput variance explained
            prediction = [pred trends(:,dcid)] * beta;
            prediction = prediction(:,1);
        end

        prediction = [pred trends(:,dcid)] * beta;
        RFs        = RFs .* (beta(1) .* M.params.analysis.HrfMaxResponse);
        
        rfParams(4) = beta(1);

   case {'Double 2D pRF fit (x,y,sigma,sigma2, center=positive)'},
        if recompFit==0,
            beta = rmCoordsGet(M.viewType, model, 'b', coords);
            beta = beta([1 2 dcid+2]);
        else
            beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
            beta(1) = max(beta(1),0);
            beta(2) = max(beta(2),-abs(beta(1)));
            
            % also recomput variance explained
            prediction = [pred trends(:,dcid)] * beta;
            prediction = prediction(:,1);
        end

        prediction = [pred trends(:,dcid)] * beta;
        RFs        = RFs * (beta(1:2).*M.params.analysis.HrfMaxResponse);

        rfParams(:,4) = beta(1);
		
    case {'Two independent 2D pRF fit (2*(x,y,sigma, positive only))'},
        if recompFit==0,
            beta = rmCoordsGet(M.viewType, model, 'b', coords);
            beta = beta([1 2 dcid+2]);
        else
            beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
            beta(1:2) = max(beta(1:2),0);
			
            prediction = [pred trends(:,dcid)] * beta;
            prediction = prediction(:,1);
        end

        prediction = [pred trends(:,dcid)] * beta;
        RFs        = RFs * (beta(1:2) .* M.params.analysis.HrfMaxResponse);

        rfParams(:,4) = beta(1:2);
        rfParams = rfParams(1,:);
		
  case {'Sequential 2D pRF fit (2*(x,y,sigma, positive only))'},
        if recompFit==0,
            beta = rmCoordsGet(M.viewType, model, 'b', coords);
            beta = beta([1 2 dcid+2]);
        else
            beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
            beta(1:2) = max(beta(1:2),0);
            % also recomput variance explained
            prediction = [pred trends(:,dcid)] * beta;
            prediction = prediction(:,1);
        end

        prediction = [pred trends(:,dcid)] * beta;
        RFs        = RFs * (beta(1:2) .* M.params.analysis.HrfMaxResponse);

        rfParams(:,4) = beta(1:2);
        rfParams = rfParams(1,:);
		
   otherwise,
        error('Unknown modelName: %s', modelName);
end;

return
