function [R h] = rmCompareModelsGUI_paramXCorr(M, plotFlag);
% Compute the cross-correlation across parameter estimates for the RM compare
% models GUI.
%
%   [R h] = rmCompareModelsGUI_paramXCorr([M=get from cur figure], [plotFlag=1]);
% 
% This correlation matrices, in which the basic pRF parameters 
% (x0, y0, sigma, polar angle, eccentricity, and variance
% explained) are correlated across the loaded models. The correlation
% matrices are returned in the matrix R.
%
%
% OUTPUTS:
% R is a 3D matrix of size nModels by nModels by 6. The six slices are
% cross-correlation matrices for, respectively:
%	1) x0
%	2) y0
%	3) sigma major
%	4) polar angle
%	5) eccentricity
%	6) variance explained.
%
% For each cross-correlation matrix, the entry R(m,n) is the Pearson's
% correlation coefficient (R) between the pattern across all voxels of the
% relevant parameter, between model m and model n. The diagonal values
% R(n,n) are all set to 1, since each set of parameters is correlated to
% itself.
%
% INPUTS:
%	
% M: compare models GUI data structure. [Default is to get it from the
% current figure.]
%
% plotFlag: indicates whether to show these matrices in a new figure. If 1 or 2,
% will return the handle of the new figure(s) in h.
%	0: don't plot
%	1: plot color-coded images of the correlation matrices
%	2: plot scatter plots for each comparison. (Will create a separate
%	figure for each pRF parameter, with the scatter plots arranged as per
%	the lower quadrant of the cross-correlation matrices.)
%
%
% ras, 04/2009.
if notDefined('M'),		M = get(gcf, 'UserData');			end
if notDefined('plotFlag'),	plotFlag = 1;					end

R = [];
h = [];

%% compute the correlation coefficients
fields = {'x0' 'y0' 'sigma' 'pol' 'ecc' 'varexp'};
for z = 1:6
	f = fields{z};  % field name
	
	data =  reshape( [M.(f){:}], [M.nVoxels M.nModels] );
	
	R(:,:,z) = corrcoef(data);
end

%% visualize if selected
if plotFlag==1
	%% plot color-coded images of the X-corr matrices
	nm = sprintf('Cross-Model Correlations %s', M.roi.name);
	h = figure('Color', 'w', 'Name', nm);
	
	for z = 1:6
		subplot(2, 3, z);
		
		drawXCorrMatrix( R(:,:,z) );
		
		% label each entry in the lower-left-hand plot
		if z==4
			axis on
			set(gca, 'Box', 'off', 'XTick', 1:M.nModels, ...
				'YTick', 1:1:M.nModels, 'FontSize', 9)
			xlabel('Model #', 'FontSize', 12);
			ylabel('Model #', 'FontSize', 12);
		end
		
		title( fields{z}, 'FontSize', 14 );
	end
	
elseif plotFlag==2
	%% plot multiple figures, with scatter plots for each correlation
	N = M.nModels - 1;  % # rows/columns of subplots in this figure
	
	for z = 1:6
		f = fields{z};  % field name
		
		nm = sprintf('Cross-Model Correlations %s', M.roi.name);
		h(z) = figure('Color', 'w', 'Name', nm);
		
		for x = 1:N
			for y = x+1:N+1
				row = y-1;
				subplot(N, N, [(row-1)*N + x]);
				regressPlot(M.(f){x}, M.(f){y}, 'x=y', 'title');
				
				if z < 3  % x0 or y0: add x=0 / y=0 line
					AX = axis;
					line(AX(1:2), [0 0], 'Color', [.5 .5 .5]);
					line([0 0], AX(3:4), 'Color', [.5 .5 .5]);
				end
				
% 				xlabel([M.dtList{x} ' ' f], 'FontSize', 12);
% 				ylabel([M.dtList{y} ' ' f], 'FontSize', 12);
				xlabel([M.params{x}.analysis.pRFmodel ' ' f], 'FontSize', 12);
				ylabel([M.params{y}.analysis.pRFmodel ' ' f], 'FontSize', 12);
            end
		end
	end
	
end

return

		
	