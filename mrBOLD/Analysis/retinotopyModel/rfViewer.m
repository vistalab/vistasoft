function rfViewer(anal)
% rfViewer - Simple GUI to step through the voxels in a set of ROIs
%
%  rfViewer(anal);
%
% Simple GUI to step through the voxels in a set of ROIs, looking
% at the best-estimate receptive field for each. The anal struct is
% computed in rmVisualizeRFs.
%
%
% ras, 08/2006.
if ischar(anal) && isequal(lower(anal), 'update')
    rfViewerUpdate;    return;
end

anal.gui.fig = figure('Color', 'w', 'Name', [mfilename ' Voxel GUI']);

% this GUI will have only one axes for showing the RF of a single
% ROI/voxel.
% first make the axes
anal.gui.axs = axes('Units', 'normalized', 'Position', [.2 .3 .6 .6]);

% plot the RF of the first voxel, first ROI
sigma = anal.sigma{1}(1);
x0 = anal.x0{1}(1); 
y0 = anal.y0{1}(1);
imagesc( rfGaussian2D(anal.X, anal.Y, sigma, sigma, 0, x0, y0) );
title('Single Voxel RF', 'FontWeight', 'bold');

% callback for the uicontrols
cb = 'rfViewer(''update''); ';     

% make a slider for moving between voxels
anal.gui.voxSlider = mrvSlider([.3 .08 .6 .08], 'Voxel', 'IntFlag', 1, ...
                                'Range', [1 length(anal.x0{1})], ...
                                'maxLabelFlag', 1, 'Color', 'w', 'cb', cb);

% make a popup for selecting the ROI
anal.gui.roiPopup = uicontrol('Style', 'popup', 'Units', 'normalized', ...
                              'Position', [.1 .08 .15 .08], 'Value', 1, ...
                              'FontSize', 12, 'String', anal.roiNames, ...
                              'BackgroundColor', 'w', 'Callback', cb);
if length(anal.roiNames)==1, set(anal.gui.roiPopup, 'Visible', 'off'); end                          

% make an axes for visualizing the pRF, and a colorbar
anal.gui.axes = subplot('Position', [.1 .3 .65 .65]);
anal.gui.cbar = subplot('Position', [.9 .3 .06 .65]);
anal.cbar = cbarCreate(jet(256), 'BOLD / mm^2', 'direction', 'vert');

% add a zoom button
cb = ['if get(gcbo,''Value'')==1, zoom on; ' ...
	  'else, zoom off; rotate3D; ' ...
	  'end '];
anal.gui.zoom = uicontrol('Style', 'checkbox', 'Units', 'normalized', ...
                              'Position', [.1 .02 .15 .08], 'Value', 0, ...
                              'FontSize', 12, 'String', 'Zoom', ...
                              'BackgroundColor', 'w', 'Callback', cb);
% add a grid button
anal.gui.grid = uicontrol('Style', 'checkbox', 'Units', 'normalized', ...
                              'Position', [.25 .02 .15 .08], 'Value', 0, ...
                              'FontSize', 12, 'String', 'Grid', ...
                              'BackgroundColor', 'w', 'Callback', 'grid');

set(anal.gui.fig, 'UserData', anal);

% do an initial draw, and initialize the view angle
rfViewerUpdate;
view(0, 90);

return
% /--------------------------------------------------------------------- / %




% /--------------------------------------------------------------------- / %
function rfViewerUpdate
anal = get(gcf,'UserData'); 
v = round( get(anal.gui.voxSlider.sliderHandle, 'Value') ); 
r = get(anal.gui.roiPopup, 'Value'); 
sigma = anal.sigma{r}(v); 
x0 = anal.x0{r}(v); y0 = anal.y0{r}(v);
RF = rfGaussian2D(anal.X, anal.Y, sigma, sigma, 0, x0, y0);

% combine w/ 2nd Gaussian if it's selected
if checkfields(anal, 'sigma2')
	sigma2 = anal.sigma2{r}(v);
	RF2 = rfGaussian2D(anal.X, anal.Y, sigma2, sigma2, 0, x0, y0);
	b1 = anal.beta{r}(v);
	b2 = anal.beta2{r}(v);
	RF = b1 .* RF + b2 .* RF2;
else
	b1 = anal.beta{r}(v);
	RF = b1 .* RF;
end

% set other GUI functions
mrvSliderSet(anal.gui.voxSlider, 'Range', [1 length(anal.x0{r})]); 

% % set cbar
% anal.cbar.clim = [min(RF(:)) max(RF(:))];
% cbarDraw(anal.cbar, anal.gui.cbar);

% draw RF
axes(anal.gui.axes); cla; hold on
X = unique(anal.X);
Y = unique(anal.Y);
% imagesc(X, Y, RF); 
surf(X, Y, RF);
shading interp
% view(0, 90);
% axis equal
% grid on
% set(gca, 'XTick', [min(X) 0 max(X)], 'YTick', [min(Y) 0 max(Y)]);
xlabel('X, degrees')
ylabel('Y, degrees')
zlabel('BOLD / deg^2')
title( sprintf('%s Voxel %i', anal.roiNames{r}, v)); 
ylabel(anal.gui.cbar, 'BOLD / deg^2');
rotate3D on;

return
