function ui = mrViewAddOverlay(ui, mapNum);
%
% ui = mrViewAddOverlay([ui], [mapNum]);
% 
% Initialize a new overlay for a mrViewer UI, by
% adding a new entry in the ui.overlays field and
% initializing a new overlay window (if the GUI is
% open).
%
%
% ras 07/05.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet; end
if ishandle(ui), ui = get(ui, 'UserData'); end

% check that there are maps to use for the overlays:
% if not, load one:
if ~isfield(ui,'maps') | isempty(ui.maps)
    ui = mrViewLoad(ui,[],1);
end

% get index of new overlay
if ~isfield(ui,'overlays') | isempty(ui.overlays)
    o = 1;
else
    o = length(ui.overlays)+1;
end

if ~exist('mapNum','var') | isempty(mapNum)
    mapNum = min(o, length(ui.maps)); 
end

% preferred order of color maps according to overly #
prefOrder = {'hot' 'winter' 'greenred' 'cool' 'autumn' ...
             'jet' 'gray' 'red' 'green' 'blue'}; 


ui.overlays(o).hide = false; % logical indicator whether to hide overlay

ui.overlays(o).mapNum = mapNum;
for j = 1:3    
    ui.overlays(o).thresholds(j).on = 0;
    ui.overlays(o).thresholds(j).mapNum = mapNum;
    ui.overlays(o).thresholds(j).min = 0;
    ui.overlays(o).thresholds(j).max = 1;
    ui.overlays(o).thresholds(j).autoScale = 0;
end
ui.overlays(o).cbar = cbarCreate(prefOrder{o});
ui.overlays(o).clim = 'auto';
ui.overlays(o).subVol = 1; % time / 4th-dimension index

% decide whether to dock based on 'dockFlag' preference variable
if ~ispref('VISTA', 'dockFlag'), setpref('VISTA', 'dockFlag', 0); end
dockFlag = getpref('VISTA', 'dockFlag');

if ishandle(ui.fig)
    ui = mrViewOverlayPanel(ui, dockFlag, o);
end

% Try to be predictive: initialize reasonable thresholds for some maps
if (strncmp(ui.maps(mapNum).dataUnits, '-log', 4) | ...
	strncmp(lower(ui.maps(mapNum).dataUnits), 't', 1)) & ...
        (ui.maps(mapNum).dataRange(1) < 2) & ...
        (ui.maps(mapNum).dataRange(2) > 2) 
    % if the map appears to be a contrast map, initialize
	% the lower threshold to 2.0
    set(ui.overlays(o).threshCheck(1), 'Value', 1);
    mrvSliderSet(ui.overlays(o).threshMin(1), 'Value', 2);
    mrvSliderSet(ui.overlays(o).threshMin(1), 'Visible', 'on');
    mrvSliderSet(ui.overlays(o).threshMax(1), 'Visible', 'on');
    set(ui.overlays(o).threshMap(1), 'Visible', 'on');
    ui.overlays(o).thresholds(1).min = 2;
    ui.overlays(o).thresholds(1).on = 1;
	
elseif strncmp(ui.maps(mapNum).name, 'Coherence', 9)
	% Coherence map: initial lower thresh is 0.20
    set(ui.overlays(o).threshCheck(1), 'Value', 1);
    mrvSliderSet(ui.overlays(o).threshMin(1), 'Value', .2);
    mrvSliderSet(ui.overlays(o).threshMin(1), 'Visible', 'on');
    mrvSliderSet(ui.overlays(o).threshMax(1), 'Visible', 'on');
    set(ui.overlays(o).threshMap(1), 'Visible', 'on');
    ui.overlays(o).thresholds(1).min = .2;
    ui.overlays(o).thresholds(1).on = 1;

elseif strncmp(ui.maps(mapNum).name, 'meanMap', 7)
	% mean map: one 'click' up on the slider
	lo = ui.maps(mapNum).dataRange(1);
	hi = ui.maps(mapNum).dataRange(2);
	thresh = lo + .1 * (hi - lo);
	
    set(ui.overlays(o).threshCheck(1), 'Value', 1);
    mrvSliderSet(ui.overlays(o).threshMin(1), 'Value', thresh);
    mrvSliderSet(ui.overlays(o).threshMin(1), 'Visible', 'on');
    mrvSliderSet(ui.overlays(o).threshMax(1), 'Visible', 'on');
    set(ui.overlays(o).threshMap(1), 'Visible', 'on');
    ui.overlays(o).thresholds(1).min = thresh;
    ui.overlays(o).thresholds(1).on = 1;
	
    
end

ui = mrViewSetOverlay(ui, ui.panels.overlays(o));
% mrViewRefresh(ui);

return


