function mv = mv_histograms(mv);
% Plot histograms of relevant parameters for a multi-voxel UI.
%
% mv = mv_histograms(mv);
%
% This function plots several histograms, summarizing some
% values across voxels which are thought to be informative.
% These values include the percent variance explained by
% a GLM model, the d' measure, and the range of amplitudes
% for each voxel and condition (determined by mv_amps).
% The code applies a GLM if it hasn't already been applied. 
%
%
% ras, 06/2007.
if notDefined('mv'),	mv = get(gcf, 'UserData');			end

% apply a GLM if needed
if ~isfield(mv, 'glm'),		mv = mv_applyGlm(mv);			end

% get d' if needed
if ~isfield(mv, 'dprime'),	mv.dprime = mv_dprime(mv);		end

% get amps if needed
if ~isfield(mv, 'amps'),	mv.amps = mv_amps(mv);		end

%% params
nVoxels = size(mv.coords, 2);
nConds = size(mv.amps, 2);
fsz = mv.params.fontsz - 2; % labels a little smaller

% figure out # of bins to use for histograms, based on # of voxels
if nVoxels < 1000	% up to 100 bins
	nBins = floor(nVoxels / 8);
else				% lots of voxels: allow more voxels / bin
	nBins = 150;
end

%% variance explained histogram
subplot(3, 1, 1);
[n x] = hist(100 .* mv.glm.varianceExplained, nBins);
bar(x, n, 'k');
xlabel('Percent Variance Explained, GLM', 'FontName', mv.params.font, ...
	'FontSize', fsz, 'FontWeight', 'bold');
ylabel('# Voxels', 'FontName', mv.params.font, ...
	'FontSize', fsz, 'FontWeight', 'bold');
set(gca, 'Box', 'off');

title(sprintf('Total # Voxels: %i', nVoxels), 'FontName', mv.params.font, ...
	'FontSize', fsz+1, 'FontWeight', 'bold');

%% d' histogram
subplot(3, 1, 2);
[n x] = hist(mv.dprime, nBins);
bar(x, n, 'k');
xlabel('d''', 'FontWeight', 'bold', 'FontAngle', 'italic', ...
	'FontName', mv.params.font, 'FontSize', fsz);
ylabel('# Voxels', 'FontName', mv.params.font, ...
	'FontSize', fsz, 'FontWeight', 'bold');
set(gca, 'Box', 'off');

%% amps histogram
% choose an appropriate string for the amplitudes
switch mv.params.ampType
	case 'betas', xstr = 'GLM \beta';
	case 'difference', xstr = 'Peak-Bsl Amplitude';
	case 'relamps', xstr = 'Projected fMRI Amplitude';
	case 'zscore', xstr = 'Z-score';
	case 'deconvolved', xstr = 'Deconvolved TC Amplitude';
	otherwise, xstr = 'fMRI Amplitude';
end

% plot
subplot(3, 1, 3);
[n x] = hist(mv.amps, nBins*nConds);
bar(x, n, 'k');
xlabel(xstr, 'FontName', mv.params.font, 'FontWeight', 'bold', ...
	'FontSize', fsz);
ylabel('# Voxels', 'FontName', mv.params.font, ...
	'FontSize', fsz, 'FontWeight', 'bold');
set(gca, 'Box', 'off');

return
