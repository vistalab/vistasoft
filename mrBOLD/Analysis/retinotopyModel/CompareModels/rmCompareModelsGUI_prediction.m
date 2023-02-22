function pred = rmCompareModelsGUI_prediction(m, M, RFvals, tSeries, maxMethod);
% Compute the predicted time series for a given pRF. 
%
%  pred = rmCompareModelsGUI_prediction(m, [M], [RFvals], [tSeries], [maxMethod]);
%  
% INPUTS:
%	m: model number.
%
%	M: rmCompareModelsGUI struct. See rmCompareModelsGUI_getData. [default:
%	get from cur figure, assuming it's a GUI]
%
%	RFvals: vector of pRF values at all stimulus points in the sampling
%	grid.
%
%
% OUTPUTS:
%
%
%
% ras, 11/14/2009, broken off rmCompareModelsGUI_update.
if notDefined('M'), M = get(gcf, 'UserData');			end
if ishandle(M), M = get(M, 'UserData');				end

if notDefined('RFvals')
	X = M.params{m}.analysis.X;
    Y = M.params{m}.analysis.Y;
	x0 = M.x0{m}(:,M.voxel);
	y0 = M.y0{m}(:,M.voxel);
	sigma = M.sigma{m}(:,M.voxel);
	RFvals  = rmPlotGUI_makeRFs(M.modelName, [x0 y0 sigma 0 sigma 0], X, Y);
end

if notDefined('tSeries') 
	tSeries = M.tSeries{m}(:,M.voxel);
end

if notDefined('maxMethod')
	if checkfields(M, 'ui', 'maxPredictionMethod') & ...
		ishandle(M.ui.maxPredictionMethod)
		maxMethod = isequal( get(M.ui.maxPredictionMethod, 'Checked'), 'on' );
	else
		maxMethod = 0;
	end
end

%% make the raw prediction
if maxMethod==1	
	% use alternate max method: 'max' function over the stimulus location
	RF = repmat(RFvals(:)', [length(t) 1]);
	pred = max( M.params{m}.analysis.allstimimages .* RF, [], 2 );

else
	% standard maxMethod: simple multiply/sum over pixels
	pred = M.params{m}.analysis.allstimimages * RFvals;

end

pred = double(pred);  % needed for some big scaling operations

%% scale the prediction to match the units of the observed time series
% make trends
[trends, ntrends, dcid] = rmMakeTrends(M.params{m}, 0);

% add the trends using re-derived beta values
beta = pinv([pred trends(:,dcid)])*tSeries;
beta(1) = max(beta(1),0);
pred = [pred trends(:,dcid)] * beta;

%% this is commented out -- remove permanently?
% occasionally the beta values will be way out of whack --
% like, an order of magnitude too large. Not quite sure the
% ultimate cause, but for now, I auto-scale the predictor to
% have the same max as the time series. As long as I make clear
% that the prediction units are arbitrary, this should be ok.
% 	pred = pred .* (max(tSeries) ./ max(pred(:)));

% some junk voxels have no pRF estimated -- I think this is caused by the
% search fit deciding not to keep the params. In this case, the RFvals will
% be empty (or all zeros), making the prediction incorrectly flat, Correct
% this case.
tmp = mrvMinmax(RFvals);
if isempty(tmp) | (tmp(1)==0 & tmp(2)==0)
	[T df RSS B] = rmGLM(tSeries, [pred trends(:,1)], [1 -1]);
	pred = abs(B(1))*pred + B(2);
end

return