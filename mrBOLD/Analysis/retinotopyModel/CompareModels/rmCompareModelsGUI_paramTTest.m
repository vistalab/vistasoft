function [p T hFig res] = rmCompareModelsGUI_paramTTest(M, plotFlag);
% Compare the distributions of pRF parameters between models in a compare
% models GUI.
%
%   [p T hFig df res] = rmCompareModelsGUI_paramTTest([M, plotFlag=1]);
%
% INPUTS:
%	M: rmCompareModelsGUI structure. See rmCompareModelsGUI_getData.
%	[Default: get from current figure]
%
%	plotFlag: flag to indicate whether to plot the results or just return
%	them. [default: 1, plot 'em]
%
% OUTPUTS:
%	p: [nModels x nModels x 7] matrix of p-values, for one-tailed T tests
%	between the parameters for each model. The 7 slices reflect the 7
%	parameters analyzed:
%		1) x0
%		2) y0
%		3) sigma (major)
%		4) polar angle
%		5) eccentricity
%		6) variance explained
%		7) beta coefficient for main pRF term.
%	So, for instance, p(2,1,3) reflects a comparison of the third parameter
%	(pRF size or sigma) for the test where model 2 is greater than model 1.
%	
%	T: [nModels x nModels x 7] matrix of T-values, corresponding to the p-
%	values given in p. 
%
%	hFig: if plotFlag==1, returns a handle to the plotted data. Otherwise,
%	returns empty.
%
%	res: further results struct, with the following fields:
%		df: degrees of freedom for the T tests
%
%		alpha: alpha threshold for the T tests, based on p=0.01 with
%		Bonferroni correction for multiple comparisons within these tests
%
%		H: matrix of 'results' indicating whether to accept (=0) or reject (=1) 
%		the null hypothesis that the parameters come from the same
%		distribution. Same format as p and T.
%
%		CI_lo, CI_hi: 100 * (1-alpha)% confidence intervals for the true mean for
%		each comparison (same format as H). CI_lo is the lower bound, CI_hi
%		is the upper bound.
%
%		sd: pooled estimate of the population standard deviation for each
%		comparison (same format as H). 
%	
%
% ras, 05/2009.
if notDefined('M'),		M = get(gcf, 'UserData');			end
if notDefined('plotFlag'),	plotFlag = 1;					end
if ishandle(M),			M = get(M, 'UserData');				end

p = [];
T = [];
hFig = [];

fields = {'x0' 'y0' 'sigma' 'pol' 'ecc' 'varexp' 'beta'};

% let's pick an alpha value that takes into account multiple comparisons
% (not that it really matters -- in the initial iteration, we don't return
% these, and let the user decide their own thresholds based on the
% p-values):
alpha = 0.01 / (7 * M.nModels);
res.alpha = alpha;

%% loop across parameters
for n = 1:7
	f = fields{n};
	
	% get the param values for all models
	if n < 7
		data = reshape( [M.(f){:}], [M.nVoxels M.nModels] );
	else
		% n==7: beta values: need the specific beta for the main
		% effect
		for m = 1:M.nModels
			tmp{m} = [ M.beta{m}(:,1) ]';
		end
		data = reshape( [tmp{:}], [M.nVoxels M.nModels] );
	end

	%% loop across model pairs
	for ii = 1:M.nModels	
		for jj = 1:M.nModels
			% run the one-sided T test
			[H P CI STATS] = ttest2(data(:,ii), data(:,jj), alpha, 'right');
			
			% record the main stat values
			p(ii,jj,n) = P;
			T(ii,jj,n) = STATS.tstat;
			
			% record other results
			res.df(ii,jj,n) = STATS.df;
			res.H(ii,jj,n) = H;
			res.CI_lo(ii,jj,n) = CI(1);
			res.CI_hi(ii,jj,n) = CI(2);
			res.sd(ii,jj,n) = STATS.sd;
		end
	end
end


%% plot if requested
if plotFlag==1
	nm = sprintf('Cross-Model T Tests %s', M.roi.name);
	h = figure('Color', 'w', 'Name', nm);
	
	for z = 1:7
		subplot(3, 3, z);
		
		% get the param values for all models
		f = fields{z};
		if z < 7
			data = reshape( [M.(f){:}], [M.nVoxels M.nModels] );
		else
			% ii==7: beta values: need the specific beta for the main
			% effect
			for m = 1:M.nModels
				tmp{m} = [ M.beta{m}(:,1) ]';
			end
			data = reshape( [tmp{:}], [M.nVoxels M.nModels] );
		end
		
		% compute the mean, SEM of the data
		Y = nanmean(data);
		E = nanstd(data); %  ./ sqrt(M.nVoxels - 1);
		
		starbar(Y, E, any(res.H(:,:,z)));
		set(gca, 'Box', 'off');  tuftify;
		xlabel('Model #', 'FontSize', 12);
		ylabel(f, 'FontSize', 12);
		
		title(f, 'FontSize', 14);
	end
	
	nm = sprintf('Cross-Model T Values %s', M.roi.name);
	h = figure('Color', 'w', 'Name', nm, 'Units', 'norm', ...
			  'Position', [.4 .3 .4 .4]);
	
	for z = 1:7
		subplot(3, 3, z);
		
		f = fields{z};
		
		drawXCorrMatrix( T(:,:,z), mrvMinmax(T) + [-.2 .2], 1 );
		
		% label each entry in the lower-left-hand plot
% 		if z==7
			axis on
			set(gca, 'Box', 'off', 'XTick', 1:M.nModels, ...
				'YTick', 1:1:M.nModels, 'FontSize', 9)
			xlabel('Model #', 'FontSize', 12);
			ylabel('Model #', 'FontSize', 12);
% 		end
		
		title( ['T Values: ' f], 'FontSize', 14 );
	end
	
end

return
