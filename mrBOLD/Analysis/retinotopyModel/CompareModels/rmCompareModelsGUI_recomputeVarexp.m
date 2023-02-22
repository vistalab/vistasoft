function M = rmCompareModelsGUI_recomputeVarexp(M);
% Recompute the variance explained field for each model in the
% rmCompareModels GUI.
%
%  M = rmCompareModelsGUI_recomputeVarexp(M);
%
% This modifies the stored variance explained field in the M structure used
% by the GUI, using the prediction code used to plot the predicted time
% courses, rather than the original model's RSS estimates. The reason is
% that there seems to be some issue with the model's estimates: for certain
% cases, the predicted variance explained by the model is clearly far too
% high, and both the time series and predictions are visibly very noisy. 
% This probably has something to do with having a low raw root-sum-squared
% error in the data (varexp = 1 - (model RSS / raw RSS)). 
%
% But until that's clearly debugged (and possibly, models are re-solved),
% this function can clean up the estimates within a GUI.
%
% Note that this process may take a while.
%
% ras, 03/2009.
if notDefined('M'),		M = get(gcf, 'UserData');			end

verbose = prefsVerboseCheck;
if verbose
	h = mrvWaitbar(0, 'Recomputing variance explained for all voxels...');
end

X = M.params{1}.analysis.X;
Y = M.params{1}.analysis.Y; 

for m = 1:M.nModels
	for v = 1:M.nVoxels
		%% get the tSeries / pRF params for the selected voxel
		for f = {'tSeries' 'x0' 'y0' 'sigma' 'pol' 'ecc'}
			eval( sprintf('%s = M.%s{m}(:,v);', f{1}, f{1}) );
		end
		beta = M.beta{m}(v,:);

		%% create a vector of params
		% (Todo: make this work for different model types)
		rfParams = [x0 y0 sigma 0 sigma 0];

% 		% modify the params if specified by the GUI
% 		rfParams = movePRF(M, rfParams, v);
% 		x0 = rfParams(1);
% 		y0 = rfParams(2);
% 		sigma = rfParams(3);

		%% get pRF values as column vectors
		RFvals = rmPlotGUI_makeRFs(M.modelName, rfParams, X, Y);

		%% get the pRF image and predicted time series
		% make predictions (add trends)
		pred = M.params{1}.analysis.allstimimages * RFvals;
		[trends, ntrends, dcid] = rmMakeTrends(M.params{m}, 0);
		pred = [pred trends(:,1)] * beta(:,1:2)';	

		% occasionally the beta values will be way out of whack --
		% like, an order of magnitude too large. Not quite sure the
		% ultimate cause, but for now, I auto-scale the predictor to
		% have the same max as the time series. As long as I make clear
		% that the prediction units are arbitrary, this should be ok.
		pred = pred .* (max(tSeries) ./ max(pred(:)));

		% compute variance explained for this voxel
		R = corrcoef([pred tSeries]);
		M.varexp{m}(v) = R(2) .^ 2;
		
		if verbose
			mrvWaitbar( (m-1)/M.nModels + v/(M.nModels * M.nVoxels), h );
		end
	end
end

if verbose, close(h);		end

if checkfields(M, 'ui', 'tSeriesAxes') & ishandle(M.ui.tSeriesAxes)
	rmCompareModelsGUI_update(M);
end

return
