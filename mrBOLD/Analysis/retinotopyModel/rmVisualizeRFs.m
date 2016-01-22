function anal = rmVisualizeRFs(view, rois, modelNum, xRange, yRange, varargin);
% rmVisualizeRFs - visualize the pattern of receptive field coverage
%
% anal = rmVisualizeRFs(view, rois, <modelNum=1>, <xRange>, <yRange>,
% <options>);
%
% Visualize the pattern of receptive field coverage across an ROI or set of
% ROIs, for a view with a retinotopy model assigned. Computes and RF density
% map for each ROI specified. [more explanation of the RF density map]
%
% When multiple models have been computed in the model file, will use the
% model specified by modelNum <default is 1>.
%
% xRange and yRange are optional specifications of the extent of visual
% field to map in the X and Y direction when computing the RF density maps.
% If omitted, the ranges are taken from the analysis parameters.
%
% options include:
%   'noplot': don't plot the results, just return the anal struct.
%   'rot', [value], rotate RF parameters clockwise by [value] degrees.
%
% ras, 08/06.
if notDefined('view'),      view = getCurView;							end
if notDefined('rois'),      rois = view.ROIs;							end
if notDefined('modelNum'),  modelNum = viewGet(view, 'RMModelNum');		end


if ~checkfields(view, 'rm', 'retinotopyModels')
	view = rmSelect(view, 1);
end

% params/defaults
plotFlag = 1;
rot = 0;

% parse options
for i = 1:length(varargin)
	switch lower(varargin{i})
		case 'noplot', plotFlag = 0;
		case 'rot', rot = varargin{i+1};
	end
end


%%%%% setup
% load the models from the model file
params = viewGet(view, 'rmParams');
model = viewGet(view, 'retinotopyModel');
model = model{modelNum};

% parse ROI specifications
rois = tc_roiStruct(view, rois);
nRois = length(rois);

% get sampled locations (for main loop)
if notDefined('xRange') | notDefined('yRange')
	xRange = unique(params.analysis.X);
	yRange = unique(params.analysis.Y);
end

[anal.X anal.Y] = meshgrid(xRange, yRange);

% get variance explained for each voxel, for sampling below:
varexp = rmGet(model, 'varExp');



%%%%% compute RF density maps
for r = 1:nRois
	anal.roiNames{r} = rois(r).name;

	% get RM params at ROI coords
	if ismember(view.viewType, {'Volume' 'Gray'})
		[I coords] = roiIndices(view, rois(r).coords, 1);
		if any(isnan(I))
			disp('NaNs detected in roi indices: ignoring unspecified voxels')
			anal.nanCoords = find(isnan(I));
			I = I( ~isnan(I) );
			nVoxels = length(I);
		end

		if isempty(coords)
			error(sprintf('ROI %s not contained in view''s coords.', rois(r).name));
		end

		anal.x0{r} = rmCoordsGet('Gray', model, 'x0', coords);
		anal.y0{r} = rmCoordsGet('Gray', model, 'y0', coords);
		anal.sigma{r} = rmCoordsGet('Gray', model, 'sigma', coords);
		anal.beta{r} = rmCoordsGet('Gray', model, 'bcomp1', coords);
        anal.varexp{r} = rmCoordsGet('Gray', model, 'varexp', coords);
        % 		anal.y0{r} = model.y0(I);
        % 		anal.sigma{r} = model.sigma.major(I);
        % 		anal.beta{r} = model.beta(1,I,1);
        %		anal.varexp{r} = varexp(I);
		
		% if 2-Gaussian model, grab 2nd sigma as well
		if strncmp(model.description, 'Double', 6)==1
			anal.sigma2{r} = model.sigma2.major(I);
			anal.beta2{r} = model.beta(1,I,2);
		end
		
		% remove voxels w/ no data (varexp=0)
		ok = find(anal.varexp{r} > 0);
		for f = {'x0' 'y0' 'sigma' 'beta' 'varexp'}
			anal.(f{1}){r} = anal.(f{1}){r}(ok);
		end
		if isfield(anal, 'sigma2')
			for f = {'sigma2' 'beta2'}
				anal.(f{1}) = anal.(f{1})(ok);
			end
		end

	else
		% not yet implemented for other view types
		error('Sorry, Not Yet Implemented.')

	end


	% rotation compensation, if requested
	if rot ~= 0
		radius = sqrt(anal.x0{r}.^2 + anal.y0{r}.^2);
		theta = atan2(anal.y0{r}, anal.x0{r});
		theta = theta - deg2rad(rot);
		theta = mod(theta, 2*pi);
		anal.x0{r} = radius .* cos(theta);
		anal.y0{r} = radius .* sin(theta);
	end


	% create a density map of the RF locations:
	anal.densityMap{r} = zeros(size(anal.X));
	fprintf('Computing RF density map for %s', rois(r).name)
	tic
	
	if plotFlag==1          % only get density maps if visualizing
		% alternate approach 11/08:
		% the density reflects the proportion voxels in the ROI for
		% which each point (x, y) is within one sigma of the pRF
		% center. To do this, each voxel contributes an RF that's a
		% uniform circle of one sigma radius:
		voxRFs = zeros( size(anal.X) );
		
		nVoxels = length(anal.sigma{r});
		for v = 1:nVoxels
			
			sigma = anal.sigma{r}(v);
			x0 = anal.x0{r}(v);
			y0 = anal.y0{r}(v); % +y means 'up', reverse of image conventions
			beta = anal.beta{r}(:,v);
% 			RF = rfGaussian2d(anal.X, anal.Y, sigma, sigma, 0, x0, y0);
			
			[TH R] = cart2pol(anal.X - x0, anal.Y - y0);
			voxRFs(:,:,v) = (R < sigma);
			
			if mod(v, 100)==0,         fprintf('.');        end
		end
		
		anal.densityMap{r} = mean(voxRFs, 3);
	end

	fprintf('done.\n');
	toc
end



%%%%% visualize
if plotFlag==1
	%%%%% show RF Density maps
	anal.fig = figure('Color', 'w', 'Name', [mfilename ' Density Maps']);
	colormap jet

	% allVals = unique([anal.densityMap{:}]);
	% colorRange = [min(allVals(:)) max(allVals(:))];
	nRows = ceil(sqrt(nRois));
	nCols = ceil(nRois/nRows);

	for r = 1:nRois

		% plot the density map
		anal.subplots(r) = subplot(nRows, nCols, r);
		clim = [1.1 .5] .* [min(anal.densityMap{r}(:)) max(anal.densityMap{r}(:))];
		imagesc(xRange, yRange, anal.densityMap{r}, clim);  colorbar;
		axis image; axis off;
		title(rois(r).name, 'FontWeight', 'bold', 'Interpreter', 'none');
		
		hold on, polarPlot([], 'MaxAmp', 15, 'RingTicks', 0:5:15, 'SigFigs', 0);

		if r==( (nRows-1)*nCols + 1 )
			axis on
			xlabel('X, degrees', 'FontWeight', 'bold');
			ylabel('Y, degrees', 'FontWeight', 'bold');
		end
	end


	%%%%% show histograms of parameter distributions in each ROI
	figHeight = min(.8, .2*nRois);
	anal.fig = figure('Color', 'w', 'Name', [mfilename ' Histograms'], ...
					  'Units', 'norm', 'Position', [.1 .1 .7 figHeight]);

	for r = 1:nRois
		nVoxels = size(anal.x0{r}, 2);
		
		% convert x0 and y0 to polar coords, to get those distributions
		[pol ecc] = cart2pol(anal.x0{r}, anal.y0{r});
		pol = rad2deg(pol - pi/2); % convert to deg CW of 12-o-clock
		
		% get distribution and bin centers
		[vDistr vBins] = hist(anal.varexp{r}, round(nVoxels/15));
		[xDistr xBins] = hist(anal.x0{r}, round(nVoxels/15));
		[yDistr yBins] = hist(anal.y0{r}, round(nVoxels/15));
		[thDistr thBins] = hist(pol, round(nVoxels/15));
		[rDistr, rBins] = hist(ecc, round(nVoxels/15));
		[sigDistr sigBins] = hist(anal.sigma{r}, round(nVoxels/15));


		% plot variance explained (black)
		subplot(nRois, 6, 6*r-5);
		hold on
		bar(vBins, vDistr, 'k', 'LineStyle', 'none');
		axis tight; AX = axis;
		set(gca, 'Box', 'off');
		txt = sprintf('* %0.2f', mean(anal.varexp{r}));
		text(mean(anal.varexp{r}), AX(3) + .8*diff(AX(3:4)), txt, ...
			'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold');
		if r==nRois
			xlabel('Var. Explained', 'FontSize', 10, 'FontWeight', 'bold');
			ylabel('# Voxels', 'FontSize', 10, 'FontWeight', 'bold');
		end
		title(anal.roiNames{r}, 'FontSize', 12, 'FontWeight', 'bold', ...
			'FontWeight', 'bold', 'Interpreter', 'none');
		
		% plot X coordinate (black)
		subplot(nRois, 6, 6*r-4);
		hold on
		bar(xBins, xDistr, 'k', 'LineStyle', 'none');
		axis tight; AX = axis;
		set(gca, 'Box', 'off');
		txt = sprintf('* %2.1f', mean(anal.x0{r}));
		text(mean(anal.x0{r}), AX(3) + .8*diff(AX(3:4)), txt, ...
			'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold');
		if r==nRois
			xlabel('X', 'FontSize', 10, 'FontWeight', 'bold');
			ylabel('# Voxels', 'FontSize', 10, 'FontWeight', 'bold');
		end

		% plot Y coordinate (black)
		subplot(nRois, 6, 6*r-3);
		hold on
		bar(yBins, yDistr, 'k', 'LineStyle', 'none');
		axis tight; AX = axis;
		set(gca, 'Box', 'off');
		txt = sprintf('* %2.1f', mean(anal.y0{r}));
		text(mean(anal.y0{r}), AX(3) + .8*diff(AX(3:4)), txt, ...
			'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold');
		hold on
		if r==nRois
			xlabel('Y', 'FontSize', 10, 'FontWeight', 'bold');
		end
		
		% plot polar angle (blue)
		subplot(nRois, 6, 6*r-2);
		hold on
		bar(thBins, thDistr, 'b', 'LineStyle', 'none');
		axis tight; AX = axis;
		set(gca, 'Box', 'off');
		txt = sprintf('* %2.1f', mean(pol));
		text(mean(pol), AX(3) + .8*diff(AX(3:4)), txt, ...
			'Color', 'b', 'FontSize', 12, 'FontWeight', 'bold');
		set(gca, 'Box', 'off', 'XTick', 0:90:360);
		for xx = 0:180:360		% mark meridians
			line([xx xx], AX(3:4), 'Color', [.3 .3 .3], 'LineStyle', '--', 'LineWidth', 0.5);
		end
		for xx = [90 270]
			line([xx xx], AX(3:4), 'Color', [.3 .3 .3], 'LineStyle', ':', 'LineWidth', 0.5);
		end		
		hold on
		if r==nRois
			xtxt = {'Polar Angle' '° CW from up'};
			xlabel(xtxt, 'FontSize', 10, 'FontWeight', 'bold');
		end

		% plot eccentricity (blue)
		subplot(nRois, 6, 6*r-1);
		hold on
		bar(rBins, rDistr, 'b', 'LineStyle', 'none');
		axis tight; AX = axis;
		set(gca, 'Box', 'off');
		txt = sprintf('* %2.1f', mean(ecc));
		text(mean(ecc), AX(3) + .8*diff(AX(3:4)), txt, ...
			'Color', 'b', 'FontSize', 12, 'FontWeight', 'bold');
		hold on
		if r==nRois
			xtxt = {'Eccentricity' 'deg'};
			xlabel(xtxt, 'FontSize', 10, 'FontWeight', 'bold');
		end


		% plot pRF diameter (red)
		subplot(nRois, 6, 6*r);
		hold on
		%         plot(sigBins, sigDistr, 'bd-');
		bar(sigBins, sigDistr, 'r', 'LineStyle', 'none');
		axis tight; AX = axis;
		set(gca, 'Box', 'off');
		txt = sprintf('* %2.1f', mean(anal.sigma{r}));
		text(mean(anal.sigma{r}), AX(3) + .8*diff(AX(3:4)), txt, ...
			'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold');
		if r==nRois
			xlabel('\sigma', 'FontSize', 11, 'FontWeight', 'bold');
		end

	end


	%%%%% also create a GUI for stepping through individual voxels
	% TODO: Fix this; it was broken when I updated the rmPlotGUI code to
	% use the sampling grid in params.analysis.X and Y (instead of x0, y0)
% 	rfViewer(anal);
end

return



% OLD CODE FOR DENSITY MAPS (TO BE REMOVED):
% 			RF = flipud(RF);  % imaging conventions: +y = up, not down
% 			anal.densityMap{r} = anal.densityMap{r} + beta .* RF;
% 			denom = max(0.001, sum(RF(:)));
% 			anal.densityMap{r} = anal.densityMap{r} + RF ./ denom;

