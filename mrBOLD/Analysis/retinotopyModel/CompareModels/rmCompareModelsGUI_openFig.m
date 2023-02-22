function M = rmCompareModelsGUI_openFig(M);
% open the GUI figure, and add controls and menus.
%
%  M = rmCompareModelsGUI_openFig(M);
%
% ras, 03/2009.
hFig = figure('Color', 'w', 'Units', 'pixels', 'Position', [100 100 800 800], ...
		   'NumberTitle', 'off', 'MenuBar', 'none', ...
		   'Name', ['pRF Compare Data Types: ' M.roi.name]);
colormap hot

%% add the voxel selection slider
% callback
cb = ['TMP = get(gcf, ''UserData''); TMP.voxel = val; ' ...
	  'rmCompareModelsGUI_update(TMP); clear TMP '];
% make the control
M.ui.voxel = mrvSlider([.8 .8 .12 .05], 'Voxel', 'Callback', cb, ...
					   'MaxLabelFlag', 1, ...
					   'IntFlag', 1, 'Range', [1 M.nVoxels], 'Value', 1);
  
%% controls for superimposing stimuli	
callback = 'rmCompareModelsGUI_update;'; 
% toggle checkbox for superimposing the stimulus image
M.ui.overlayStimCheck = uicontrol('Style', 'checkbox', ...
    'Units', 'norm', 'Position', [.8 .66 .15 .06], ...
    'BackgroundColor', 'w', 'FontSize', 9, ...
    'Callback', callback, 'Min', 0, 'Max', 1, ...
    'String', 'Overlay Stimulus on PRF', 'Value', 0);

% time point selection slider (for stimulus overlay)
M.ui.time = mrvSlider([.8 .6 .15 .06], 'Time Frame', ...
    'Range', [1 size(M.tSeries{1}, 1)], 'IntFlag', 1, 'Value', 1, ...
	'FontSize', 9, ...
    'MaxLabelFlag', 1, 'Visible', 'off', ...
    'Color', 'w', 'Callback', callback);

				   
%% add text fields for voxel information
% voxel coordinates
M.ui.coordsText = uicontrol('Units', 'norm', 'Position', [.8 .72 .16 .06], ...
							'Style', 'text', 'String', 'Coords:', ...
							'HorizontalAlignment', 'left', ...
							'BackgroundColor', get(gcf, 'Color'));

%% add controls to adjust manually adjust all pRFs
callback = 'rmCompareModelsGUI_update;'; 

% checkbox to toggle manual adjustment
M.ui.movePRF = uicontrol('Style', 'checkbox', 'Value', 0, ...
						 'String', 'Manual pRF for all models', ...
						 'Units', 'norm', 'Position', [.8 .53 .15 .03], ...
						 'BackgroundColor', 'w', 'Visible', 'on', ...
						 'HorizontalAlignment', 'left', ...
						 'Callback', callback);

% sliders for manual adjustment of x, y, sigma 
tmp = zeros(1, length(M.params));
for m = 1:length(M.params)
    tmp(m) = M.params{m}.analysis.maxRF;
end
tmp = max(tmp);

M.ui.moveX = mrvSlider([.8 .48 .15 .05], 'x', ...
    'Range', [-tmp tmp], 'IntFlag', 0, 'Value', 0, ...
	'FlexFlag', 1, 'FontSize', 8, ...
	'MaxLabelFlag', 1, 'Visible', 'off', ...
    'Color', 'w', 'Callback', callback);

M.ui.moveY = mrvSlider([.8 .43 .15 .05], 'y', ...
    'Range', [-tmp tmp], 'IntFlag', 0, 'Value', 0, ...
	'FlexFlag', 1, 'FontSize', 8, ...
	'MaxLabelFlag', 1, 'Visible', 'off', ...
    'Color', 'w', 'Callback', callback);

M.ui.moveSigma = mrvSlider([.8 .38 .15 .05], 'sigma', ...
    'Range', [0.01 15], 'IntFlag', 0, 'Value', .1, ...
	'FlexFlag', 1, 'FontSize', 8, ...
    'MaxLabelFlag', 1, 'Visible', 'off', ...
    'Color', 'w', 'Callback', callback);

% popup to set (x, y, sigma) to the solution from one of the loaded models
list = ['(Use pRF from model)' M.dtList];
M.ui.moveToPreset = uicontrol('Style', 'popup', 'String', list, ...
							  'Units', 'norm', 'Position', [.8 .34 .15 .03], ...
							  'BackgroundColor', 'w', 'Visible', 'off', ...
							  'HorizontalAlignment', 'left', ...
							  'Value', 1, ...
							  'Callback', 'rmCompareModelsGUI_setPreset;');
						
%% make axes for the time series plots
% compute width, height of each plot, based on the # of plots
w = .38;
h = 1 / (M.nModels * 1.7857);
for m = 1:M.nModels
	pos = [.05, 1.06 - (m / M.nModels), w, h];
	M.ui.tSeriesAxes(m) = subplot('Position', pos);
end

%% make axes for the RF plots
% compute width, height of each plot, based on the # of plots
% (keep constant for now, correct if/when I start looking at so many models
% as to make the height < .08)
w = .15;
h = min(.15, 1/(M.nModels*1.7857));
for m = 1:M.nModels
	pos = [.51, 1.08 - (m / M.nModels), w, h];
	M.ui.rfAxes(m) = subplot('Position', pos);
end

%% add menus
M = rmCompareModelsGUI_menus(M, hFig);

%% finalize the M struct, place in figure's UserData
% record the figure handle
M.fig = hFig;

% set selected parameters: voxel, others...?
M.voxel = 1;

% remember the previously-selected voxel for manual editing of pRFs
M.prevVoxel = 0;

% set in figure's UserData
set(hFig, 'UserData', M);

return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function M = rmCompareModelsGUI_menus(M, hFig);
%% add pulldown menus to the GUI.
M.ui.menus = uimenu(hFig, 'Label', 'pRF Plot Options');   
   
% temporally blur time series  (a hack, there should be a better way)
cb = ['TMP = get(gcf, ''UserData''); ' ...
	  'for m = 1:TMP.nModels, ' ...
	  '   for v = 1:size(TMP.tSeries{m}, 2), ' ...
	  '		 TMP.tSeries{m}(:,v) = imblur( TMP.tSeries{m}(:,v) ); ' ...
	  '   end; ' ...
	  'end; ' ...
	  'set(gcf, ''UserData'', TMP); ' ...
	  'clear TMP v; ' ...
	  'rmCompareModelsGUI(''update''); '];
uimenu(M.ui.menus, 'Label', 'Temporally blur time series', ...
	   'Callback', cb, 'Separator', 'off');
   
%% run a T test between models
cb = ['rmCompareModelsGUI_ttest();'];
uimenu(M.ui.menus, 'Label', 'T test between models (for this voxel)', ...
	   'Callback', cb, 'Separator', 'on');
   
%% toggle menus for different options   
callback = ['umtoggle(gcbo); rmCompareModelsGUI_update; ']; 
% disabled adjust pRF menu: made it a checkbox instead
% M.ui.movePRF = uimenu(M.ui.menus, 'Label', 'Adjust pRF', ...
% 					 'Separator', 'on', ...
% 					 'Callback', callback, 'Checked', 'off');

M.ui.maxPredictionMethod = uimenu(M.ui.menus, 'Label', 'Max Prediction Method', ...
					 'Separator', 'on', 'Checked', 'off', ...
					 'Callback', callback);


% scale pRF to peak or max
M.ui.peakCheck = uimenu(M.ui.menus, 'Label', 'Scale to peak', ...
					 'Separator', 'off', 'Checked', 'off', ...
					 'Callback', callback);

% recompute betas?
M.ui.recompFit = uimenu(M.ui.menus, 'Label', 'Recompute fit', ...
					 'Separator', 'off', 'Checked', 'on', ...
					 'Callback', callback);
				 
   
% Dump data to workspace
callback = ['M = get(gcf, ''UserData''); ' ...
			'tmp = M.currTsdata; '...
			'disp(''Full model data in "M". Plot data in "tmp".'') '];
uimenu(M.ui.menus, 'Label', 'Dump Plot Data to Workspace', ...
	   'Callback', callback, 'Separator', 'off');
   
% add a menu option that will toggle the rest of the toolbar menus
addFigMenuToggle(M.ui.menus);   

%% sort/select voxels menu
M.ui.menus(2) = uimenu(hFig, 'Label', 'Sort/Select Voxels');

% sort voxels by percent variance explained
uimenu(M.ui.menus(2), 'Label', 'Sort Voxels by variance explained', ...
	   'Callback', 'rmCompareModelsGUI_sortVoxels(''varexp''); ', 'Separator', 'off');
   
% sort voxels by eccentricity
uimenu(M.ui.menus(2), 'Label', 'Sort Voxels by eccentricity', ...
	   'Callback', 'rmCompareModelsGUI_sortVoxels(''ecc''); ', 'Separator', 'off');

% sort voxels by polar angle
uimenu(M.ui.menus(2), 'Label', 'Sort Voxels by polar angle', ...
	   'Callback', 'rmCompareModelsGUI_sortVoxels(''pol''); ', 'Separator', 'off');
   
% sort voxels by pRF size
uimenu(M.ui.menus(2), 'Label', 'Sort Voxels by pRF size (sigma major)', ...
	   'Callback', 'rmCompareModelsGUI_sortVoxels(''sigma''); ', 'Separator', 'off');
uimenu(M.ui.menus(2), 'Label', 'Sort Voxels by pRF size (sigma minor)', ...
	   'Callback', 'rmCompareModelsGUI_sortVoxels(''sigmaminor''); ', 'Separator', 'off');

% select a subset of voxels
cb = ['rmCompareModelsGUI_selectVoxels(gcf, [], 2); rmCompareModelsGUI_update; '];
uimenu(M.ui.menus(2), 'Label', 'Sub-select voxels', ...
	   'Callback', cb, 'Separator', 'off');

%% analyses menu
M.ui.menus(3) = uimenu(hFig, 'Label', 'Analysis');

% across-voxels x-correlations between each pair of models
cb = ['rmCompareModelsGUI_paramXCorr; '];
uimenu(M.ui.menus(3), 'Label', 'Across-model correlations of pRF params', ...
	   'Callback', cb, 'Separator', 'off');

% across-voxels scatterplots between each pair of models
cb = ['rmCompareModelsGUI_paramXCorr([], 2); '];
uimenu(M.ui.menus(3), 'Label', 'Across-model param scatterplots (many figures)', ...
	   'Callback', cb, 'Separator', 'off');
   
% across-voxels T tests between each pair of models
cb = ['rmCompareModelsGUI_paramTTest; '];
uimenu(M.ui.menus(3), 'Label', 'Across-model T tests of pRF param distributions', ...
	   'Callback', cb, 'Separator', 'off');

% across-voxels T test for single voxel
cb = ['rmCompareModelsGUI_ttest; '];
uimenu(M.ui.menus(3), 'Label', 'Compare beta sizes, current voxel', ...
	   'Callback', cb, 'Separator', 'off');
   
   
% recompute variance explained
cb = 'rmCompareModelsGUI_recomputeVarexp; ';
uimenu(M.ui.menus(3), 'Label', 'Recompute variance explained for all voxels', ...
	   'Callback', cb, 'Separator', 'off');
   

%% also add a help menu
helpMenu([], 'PRF_Tutorial');

return