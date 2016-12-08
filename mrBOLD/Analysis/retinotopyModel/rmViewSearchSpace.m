function hFig = rmViewSearchSpace(VI, XI, YI, SI, v);
% Visualize the pRF parameter search space for a given voxel.
%
%  hFig = rmViewSearchSpace(VI, XI, YI, SI, [voxel=1]);
%
% This function works on matrices produced by rmLoadSearchSpace. It creates
% a figure showing different slices for different sigma values (in SI),
% where the X axis is different x0 values and the Y axis is different y0
% values. The figure handle is returned.
%
%
% ras, 01/2009.
if nargin < 4, error('Need VI, XI, YI, and SI.');  end
if notDefined('v'), v = 1;                         end

%% setup

% grab the values for the selected voxel
VI = VI(:,:,:,v);

% get the unique values used in the XI, YI, and SI grids
X = unique(XI(:));
Y = unique(YI(:));
S = unique(SI(:));

% decide how many subplots to use
% we'll have a maximum of 25, and use all values of S if we can:
N = min( length(S), 25 );

% which sigma values are we plotting?
if N==length(S)
    % we're using all of them
    iS = 1:length(S);
    sVals = S;
else
    % showing only a subset: space evenly
    iS = round(linspace(1, length(S), N));
    sVals = S(iS);
end

% decide the number of rows and columns
nrows = ceil( sqrt(N) );
ncols = ceil( N / nrows );

% decide a color limit to use for plotting
% clim = [.1 .6];  % lock in for now
clim = [0 max(VI(:))];
% clim = mrvMinmax(VI);

%%%%% plot
% open the figure
hFig = figure('Color', 'w', 'Units', 'norm', 'Position', [.2 .2 .5 .5]);

%% loop across subplots
for n = 1:N
    hAx(n) = subplot(nrows, ncols, n);
    imagesc( X, Y, VI(:,:,iS(n)), clim );
    axis image;     grid on
    
    title( sprintf('\\sigma = %2.1f', sVals(n)) );
    
    if mod(n, ncols)==1 & ceil(n / ncols)==nrows
        xlabel( sprintf('x_0, %s', char(176)) );
        ylabel( sprintf('y_0, %s', char(176)) );
    end
end

%% add a colorbar
hP1 = mrvPanel('right', .12);
data.cbar = cbarCreate('jet', 'Variance Explained', ...
				       'direction', 'vert', 'Clim', clim);
cbarAx = axes('Parent', hP1, 'Units', 'norm', 'Position', [.5 .3 .15 .4]);
cbarDraw(data.cbar, cbarAx);

%% add info on the global maximum in the search space
maxVal = nanmax(VI(:));
iMax = find( VI == maxVal );
nPoints = length(iMax);
if length(iMax) <= 10
	xx = XI(iMax);
	yy = YI(iMax);
	ss = SI(iMax);
	
    % show iMax points as dots in the search space
	[pointsInSubplots whichSubplots] = ismember(ss, sVals);
	whichPoints = find(pointsInSubplots);
	
	for ii = whichPoints(:)'
		axes( hAx(whichSubplots(ii)) );
		hold on
		plot( xx(ii), yy(ii), 'wo', 'MarkerSize', 2 );
	end
end

txt = [sprintf('Maximum Variance Explained: %2.1f%%\n', maxVal*100) ...
	   sprintf('%i unique point(s) at maximum fitness. \n', nPoints)];
if length(iMax) <= 10
    % report each point
    txt = [txt sprintf('(x, y, sigma) points: ')];
    
    for ii = 1:length(iMax)
        ptStr = sprintf('(%2.1f %2.1f %2.1f) ', ...
                        XI(iMax(ii)), YI(iMax(ii)), SI(iMax(ii)));
        txt = [txt ptStr];
    end
end

% put up the text in a panel
hP3 = mrvPanel('above', .1, [], [], 'BackgroundColor', 'w');
uicontrol('Parent', hP3, 'Units', 'norm', 'Position', [.1 .1 .8 .8], ...
          'Style', 'text', 'String', txt, 'Min', 1, 'Max', 11, ...
		  'BackgroundColor', 'w', 'HorizontalAlignment', 'left', ...
		  'FontSize', 9);


%% store useful info in the figure's UserData
data.VI = VI;
data.XI = XI;
data.YI = YI;
data.SI = SI;
data.clim = clim;
data.cbarAx = cbarAx;
data.plots = hAx;
set(hFig, 'UserData', data);

%% add sliders to adjust the color limits
% put them in a panel beneath the figure
hP2 = mrvPanel('below', .12);

% min slider
cb = ['TMP = get(gcf, ''UserData''); ' ...
	  'TMP.cbar.clim(1) = val; ' ...
	  'for ax = TMP.plots, ' ...
	  '  set(ax, ''Clim'', TMP.cbar.clim); ' ...
	  'end; ' ...		 
	  'cbarDraw(TMP.cbar, TMP.cbarAx); ' ...
	  'clear ax TMP'];
hMin = mrvSlider([.1 .3 .3 .35], 'CMin', 'Range', mrvMinmax(VI), ...
				 'Value', clim(1), 'Callback', cb, ...
				 'FlexFlag', 1, 'Parent', hP2);
			 
% max slider			 
cb = ['TMP = get(gcf, ''UserData''); ' ...
	  'TMP.cbar.clim(2) = val; ' ...
	  'for ax = TMP.plots, ' ...
	  '  set(ax, ''Clim'', TMP.cbar.clim); ' ...
	  'end; ' ...		 
	  'cbarDraw(TMP.cbar, TMP.cbarAx); ' ...
	  'clear ax TMP'];
hMax = mrvSlider([.5 .3 .3 .35], 'CMax', 'Range', mrvMinmax(VI), ...
				 'Value', clim(2), 'Callback', cb, ...
				 'FlexFlag', 1, 'Parent', hP2);
			 
% also add a button to use 'imclick'
uicontrol('Parent', hP2, 'Style', 'pushbutton', ...
		  'String', 'imclick', 'Callback', 'imclick(5); ', ...
		  'Units', 'norm', 'Position', [.81 .3 .15 .2]);


return
