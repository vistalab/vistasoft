function [xfit Rdata h] = rmCompareModelsGUI_crossModelFit(M, plotFlag);
% Use the estimated pRF from each model to fit each of the different time
% series. 
%
%   [xfit Rdata h] = rmCompareModelsGUI_crossModelFit([M=get from cur figure], [plotFlag=1]);
% 
%
% This code will compute a matrix of the cross-fits -- that is, the
% variance explained when the pRF from one model is fit to the data from
% another model -- for each voxel in the compare models GUI. It also
% computes the cross-correlation between the observed time series, to
% indicate the overall similarity in the signals to be fit. 
%
% If the plot flag is set, it will display the cross-fit correlations and
% data cross-correlations for the selected voxel in the GUI, as well as the
% mean value across voxels for each matrix.
%
% INPUTS:
%	
% M: compare models GUI data structure. [Default is to get it from the
% current figure.]
%
% plotFlag: indicates whether to show these matrices in a new figure.
% [default 1]
%
% OUTPUTS:
% xfit and R are both 3D matrices of size nModels by nModels by nVoxels. 
%
% The entry xfit(m,n) is the goodness-of-fit (proportion variance
% explained) of the pRF from model n for the time series m.
%
% R(m,n) is the cross-correlation between the observed time series m and n.
% The diagonals of R are 1 (auto-correlation).
%
% h is a handle to the plot figure (if plotFlag==1).
%
%
%
% ras, 04/2009.
if notDefined('M'),		M = get(gcf, 'UserData');			end
if notDefined('plotFlag'),	plotFlag = 1;					end

xfit = [];
Rdata = [];
h = [];

%% mark the currently selected voxel, to restore after we compute values
%% for each voxel
curVoxel = M.voxel;

%% compute the cross-fits and cross-correlations
for v = 1:M.nVoxels
	M.voxel = v;
	
	% get the time series for this voxel, for each model
	% (this will have problems if the different time series are different
	% sizes...)
	for m = 1:M.nModels
		tSeries(:,m) = M.tSeries{m}(:,v);
	end
	
	for m = 1:M.nModels
		% get the predicted time series for this model
		pred = rmCompareModelsGUI_prediction(m, M);
		
		% compute the cross fits
		R = corrcoef([pred tSeries]);
		
		% take the correlation values into the two output variables
		%
		% the first column has this prediction's fit to each observed time
		% series.
		xfit(:,m,v) = R(2:end,1) .^ 2; % var. exp = R^2
		
		% the sub matrix with (rows, cols) from 2:end is the data
		% x-correlation. This is computed for free, but we only need to
		% grab it once per voxel:
		if m==1
			Rdata(:,:,v) = R(2:end,2:end);
		end
	end
end

% restore the initially-selected voxel
M.voxel = curVoxel;

%% visualize if selected
if plotFlag==1
	%% plot color-coded images of the X-corr matrices
	nm = sprintf('Cross-Model Fits %s', M.roi.name);
	h = figure('Color', 'w', 'Name', nm);
	
	% (1) cross-fits for the selected voxel
	subplot(221);
	drawXCorrMatrix( xfit(:,:,M.voxel) );
	axis on
	title(sprintf('Cross-Fit, Voxel %i', M.voxel));
	xlabel('pRF Model');
	ylabel('Data Type');

	% (2) data x-corr for the selected voxel
	subplot(222);
	drawXCorrMatrix( Rdata(:,:,M.voxel) );
	axis on
	title(sprintf('Cross-Fit, Voxel %i', M.voxel));
	xlabel('Data Type');
	ylabel('Data Type');

	% (3) mean cross-fit across voxels
	subplot(223);
	drawXCorrMatrix( nanmean(xfit, 3) );
	axis on
	title(sprintf('Mean Cross-Fit, %i Voxels', M.nVoxels));
	xlabel('pRF Model');
	ylabel('Data Type');
	
	% (4) cross-fits for the selected voxel
	subplot(224);
	drawXCorrMatrix( nanmean(Rdata, 3) );
	axis on
	title(sprintf('Mean Data XCorr, %i Voxels', M.nVoxels));
	xlabel('Data Type');
	ylabel('Data Type');
end

return

		
	