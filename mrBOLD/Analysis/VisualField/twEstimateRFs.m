function anal = twEstimateRFs(view, rois, dt, scans, varargin);
% twEstimateRFs - estimate population receptive field (pRF) parameters
% based on a simple analysis traveling-wave results.
%
% anal = twEstimateRFs(view, rois, <dt='Averages'>, <scans=[1 2]>, ...
%							<xRange>, <yRange>, <options>);
%
% To run this, you should have two scans with polar angle and eccentricity
% mapping data in a common data type, with the simple retinotopic mapping
% parameters set for each (see retinoSetParams). 
%
% INPUTS:
%  'view': mrVista view. [Defaults to current view]
%	rois: specification of ROIs in the view to analyze.
%	dt: data type of the relevant traveling wave data.
%	scans: 1x2 vector of scans containing the polar angle and
%		eccentricity data, respectively.
%
% 
% options include:
%	'plot': compute an RF density map, and plot all results.
%   'noplot': don't plot the results, just return the anal struct.
%	'plotFlag': specify 1x3 logical vector specifying which of 3 plots to show:
%		plotFlag(1)==1: plot the RF density map.
%		plotFlag(2)==1: plot histograms of the parameter distributions.
%		plotFlag(3)==1: put up an RF broswer for browsing single voxel RFs.
%   'rot', [value], rotate RF parameters clockwise by [value] degrees.
%	'xRange', [value]
%	'yRangge', [value]: xRange and yRange are optional specifications of the extent of visual
% field to map in the X and Y direction when computing the RF density maps.
% If omitted, the ranges are taken from the analysis parameters.
% ras, 08/06.
if notDefined('view'),      view = getCurView;                  end
if notDefined('dt'),		dt = 'Averages';					end
if notDefined('scans'),		scans = [1 2];						end
if notDefined('rois'),      rois = view.ROIs;                   end

% params/defaults
plotFlag = 0;  
rot = 0;
xRange = -20:.5:20;
yRange = -14:.5:14;

% parse options
for i = 1:length(varargin)
	if ischar(varargin{i})
		switch lower(varargin{i})
			case 'plot', plotFlag = [1 1 1];
			case 'noplot', plotFlag = 0;
			case 'plotflag', plotFlag = varargin{i+1};
			case 'rot', rot = varargin{i+1};
			case 'xrange', xRange = varargin{i+1};
			case 'yrange', yRange = varargin{i+1};
		end
	end
end


%%%%% setup
% parse ROI specifications
rois = tc_roiStruct(view, rois);
nRois = length(rois);

[anal.X anal.Y] = meshgrid(xRange, yRange);

% ensure a corAnal has been computed for this data type / scans
view = selectDataType(view, dt);
twPath = fullfile(dataDir(view), 'corAnal.mat');
if ~exist(twPath, 'file')
	error('No corAnal file found for this data type.');
end

load(twPath, 'co', 'amp', 'ph');
if isempty(co{scans(1)}) | isempty(co{scans(2)})
	error( sprintf('Traveling wave analysis not found for %s scans %s', ...
				   dt, num2str(scans)) )
end

% check that simple retinotopy params have been set for the relevant
% scans
twParams = retinoCheckParams(view, dt, scans);

%% get the data for all voxels
% (this also converts from cell arrays to vectors of indices I)
% coherence (~= varexp)
co1 = co{scans(1)};
co2 = co{scans(2)};
clear co

% amplitude (~= beta scaling)
amp1 = amp{scans(1)};
amp2 = amp{scans(2)};
clear amp

% polar angle 
theta = polarAngle(ph{scans(1)}, twParams(1));
theta = deg2rad(90 - theta); % convert to radians CCW from 3-o-clock

% eccentricity
ecc = eccentricity(ph{scans(2)}, twParams(2));

clear ph


%%%%% get the data
for r = 1:nRois
    anal.roiNames{r} = rois(r).name; 
    
    % get RM params at ROI coords
	[I coords] = roiIndices(view, rois(r).coords, 1);
	if any(isnan(I))
		disp('NaNs detected in roi indices: ignoring unspecified voxels')
		I = I( ~isnan(I) );
		nVoxels = length(I);
	end

	if isempty(coords)
		error(sprintf('ROI %s not contained in view''s coords.', rois(r).name));
	end

	nVoxels = length(I);
	anal.pol{r} = rad2deg(pi/2 - theta(I));
	anal.ecc{r} = ecc(I);
	[anal.x0{r} anal.y0{r}] = pol2cart(theta(I), ecc(I));
	anal.sigma{r} = ones(1, nVoxels); % simple constant for now
	anal.beta{r} = nanmean([amp1(I); amp2(I)]);
	anal.varexp{r} = nanmean([co1(I); co2(I)]);

    
    % rotation compensation, if requested
    if rot ~= 0
        radius = sqrt(anal.x0{r}.^2 + anal.y0{r}.^2);
        theta = atan2(anal.y0{r}, anal.x0{r});
        theta = theta - deg2rad(rot);
        theta = mod(theta, 2*pi);
        anal.x0{r} = radius .* cos(theta);
        anal.y0{r} = radius .* sin(theta);
    end

    

	if plotFlag==1		% only get density maps if visualizing
		% create a density map of the RF locations:
		anal.densityMap{r} = zeros(size(anal.X));
		fprintf('Computing RF density map for %s', rois(r).name)
		
		for v = 1:nVoxels
			sigma = anal.sigma{r}(v);
			x0 = anal.x0{r}(v);
			y0 = anal.y0{r}(v); % +y means 'up', reverse of image conventions
			beta = anal.beta{r}(:,v);
			RF = rfGaussian2d(anal.X, anal.Y, sigma, sigma, 0, x0, y0);
			RF = flipud(RF);  % MATLAB conventions: +Y is down instead of up
			anal.densityMap{r} = anal.densityMap{r} + beta .* RF;
			if mod(v, 100)==0,         fprintf('.');        end
		end
	end
	
    fprintf('done.\n');
end



%%%%% visualize
% setting plot flag to 1 means 'plot all'; but also allow the user
% to specify WHICH plots to put up, in the vector:
% [plotDensityMaps, plotHistograms, plotRFViewer]
if isequal(plotFlag, 1)
	plotFlag = [1 1 1];
elseif isequal(plotFlag, 0)
	plotFlag = [0 0 0];
else
	plotFlag(end+1:3) = 0; % pad to size 3
end

%%%%% show RF Density maps, if selected
if plotFlag(1)==1
    anal.fig = figure('Color', 'w', 'Name', [mfilename ' Density Maps']);
    colormap jet
	
	%% parameters for polarPlot
	params.grid = 'on';
	params.line = 'off';
	params.gridColor = [.9 .9 .9];
	params.fontSize = 9;
	params.symbol = '.';
	params.size = 5;
	params.color = 'w';
	params.fillColor = 'w';
	params.maxAmp = 1;
	params.ringTicks = [0:4:12];
	params.units = 'degrees';


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
		hold on, polarPlot(0, params);
        title(rois(r).name, 'FontWeight', 'bold', 'Interpreter', 'none');

        if r==( (nRows-1)*nCols + 1 )
            axis on
            xlabel('X, degrees', 'FontWeight', 'bold');
            ylabel('Y, degrees', 'FontWeight', 'bold');
        end
    end
end



%%%%% show histograms of parameter distributions in each ROI, if selected
if plotFlag(2)==1
    anal.fig = figure('Color', 'w', 'Name', [mfilename ' Histograms']);

    for r = 1:nRois
        nVoxels = size(anal.x0{r}, 2);
        [polDistr polBins] = hist(anal.pol{r}, round(nVoxels/15));
        [eccDistr eccBins] = hist(anal.ecc{r}, round(nVoxels/15));

        
        subplot(nRois, 3, 3*r-2);
        hold on
%         plot(polBins, polDistr, 'ks-');
        bar(polBins, polDistr, 'k');
        axis tight; AX = axis;
        set(gca, 'Box', 'off');
        txt = sprintf('* %2.1f', mean(anal.x0{r}));
        text(mean(anal.x0{r}), AX(3) + .8*diff(AX(3:4)), txt, ...
            'Color', 'k', 'FontSize', 18, 'FontWeight', 'bold');        
        if r==nRois
            xlabel('Polar Angle from Vertical (°)', 'FontSize', 10);
            ylabel('# Voxels', 'FontSize', 10);            
        end
        title(anal.roiNames{r}, 'FontSize', 14, 'FontWeight', 'bold');
        
		% mark meridians
		AX = axis;
		for xx = 0:180:360		
			line([xx xx], AX(3:4), 'Color', [.3 .3 .3], 'LineStyle', '--', 'LineWidth', 0.5);
		end
		for xx = [90 270]
			line([xx xx], AX(3:4), 'Color', [.3 .3 .3], 'LineStyle', ':', 'LineWidth', 0.5);
		end 
		yy = AX(3) + 1.1 * diff(AX(3:4));
		text(0, yy, 'up', 'FontSize', 10, 'FontWeight', 'bold', 'FontAngle', 'italic', 'HorizontalAlignment', 'center');
		text(90, yy, 'right', 'FontSize', 10, 'FontWeight', 'bold', 'FontAngle', 'italic', 'HorizontalAlignment', 'center');
		text(180, yy, 'down', 'FontSize', 10, 'FontWeight', 'bold', 'FontAngle', 'italic', 'HorizontalAlignment', 'center');
		text(270, yy, 'left', 'FontSize', 10, 'FontWeight', 'bold', 'FontAngle', 'italic', 'HorizontalAlignment', 'center');
		text(360, yy, 'up', 'FontSize', 10, 'FontWeight', 'bold', 'FontAngle', 'italic', 'HorizontalAlignment', 'center');
		set(gca, 'TickDir', 'out', 'Box', 'off', 'XTick', [0:90:360]);
		axis([-45 405 AX(3:4)]);

		
        subplot(nRois, 3, 3*r-1);
        hold on
%         plot(eccBins, eccDistr, 'ro-');
        bar(eccBins, eccDistr, 'k');
        axis tight; AX = axis;
        set(gca, 'Box', 'off');
        txt = sprintf('* %2.1f', mean(anal.y0{r}));
        text(mean(anal.y0{r}), AX(3) + .8*diff(AX(3:4)), txt, ...
            'Color', 'r', 'FontSize', 18, 'FontWeight', 'bold');        
        hold on
        if r==nRois
            xlabel('Eccentricity (visual °)', 'FontSize', 10);
        end                

    end
end

%%%%% also create a GUI for stepping through individual voxels
if plotFlag(3)==1
	rfViewer(anal);
end

return
