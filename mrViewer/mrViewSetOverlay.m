function ui = mrViewSetOverlay(ui, varargin);
%
%  ui = mrViewSetOverlay(ui, handle);
%
% or
%
%  ui = mrViewSetOverlay(ui, param, val, o);
%
%  Set threshold,  colormap,  and map selection for an overlay.
% Can be called a couple of ways:
% mrViewSetOverlay(ui, handle),  where handle is an overlay
% UI panel,  will set all fields in the appropriate overlay
% to those specified by the UI controls. (See mrViewOverlayPanel).
% mrViewSetOverlay(ui, param, val, o) will set the named parameter
% param to the specified value val,  for overlay # o.
%
% PARAMS:
%   threshmin:  vector of min vals for each threshold. 
%   threshmax:  vector of max vals for each threshold.
%   threshmap:  vector of indices describing which map (of the set
%               of loaded maps) to use for each threshold.
%   threshon:   vector of binary toggles for each threshold.
%   colormap:   Nx3 vector to use as a colormap for that overlay,
%               or name (from possibilities in mrvColorMaps).
%   clim:       color limits ("clip mode") for overlay. Can be 
%               'auto' (determine limits based on the displayed data)
%               or a vector of [min max] (scale color map to span this
%               range).
%   mapname:    set the name of the map displayed in this overlay.
%   dataunits:  set the name for the data units of the map displayed in the
%               overlay.
%   hide:       set the hide state of an overlay (1 hide, 0 show).
%
% ras 07/05.
% ras 09/06: can specify threshold values as params
if ~exist('ui', 'var') | isempty(ui),  ui = mrViewGet;        end
if ishandle(ui), ui = get(ui, 'UserData'); end

if length(varargin)==1 & ishandle(varargin{1})
	%% user provided a handle to an overlay panel -- use the panel settings
    o = find(ui.panels.overlays==varargin{1});
    ui = setOverlayFromUI(ui, o);
    
elseif length(varargin)==2
	%% param provided, but no value: error
	error('Not enough input args.');
	    
elseif length(varargin) >= 4       
	%% set many params at once 
    o = varargin{end};
    for ii = 1:ceil( (length(varargin)-1) / 2 )
        ui = mrViewSetOverlay(ui, varargin{2*ii-1}, varargin{2*ii}, o);
    end
    return
    
else
	%% main case: exactly 4 input arguments
    param = varargin{1};
    val = varargin{2};
    o = varargin{3};
	
	if length(o) > 1	% recursively set each overlay
		for iOverlay = o
			ui = mrViewSetOverlay(ui, param, val, iOverlay);
		end
		return
	end
	
    switch lower(param)
        case 'threshmin'    % val is vector of min vals for each threshold
            for th = 1:length(val)
                ui.overlays(o).thresholds(th).min = val(th);
                mrvSliderSet(ui.overlays(o).threshMin(th), 'Value', val(th));                
            end

        case 'threshmax'    % val is vector of max vals for each threshold
            for th = 1:length(val)
                ui.overlays(o).thresholds(th).max = val(th);
                mrvSliderSet(ui.overlays(o).threshMax(th), 'Value', val(th));                
            end

        case 'threshmap'    % val is vector of map nums for each threshold
            for th = 1:length(val)
                ui.overlays(o).thresholds(th).mapNum = val(th);
                set(ui.overlays(o).threshMap(th), 'Value', val(th));                
            end

        case 'threshon'     % val is vector of binary flags for each threshold
            for th = 1:length(val)
                ui.overlays(o).thresholds(th).on = val(th);                
                set(ui.overlays(o).threshCheck(th), 'Value', val(th));
			end            
			
		case {'colorbar' 'cbar'}	% colorbar structure
			if ischar(val)		% path to saved cbar
				val = cbarLoad(val);
			end
			
			if ~isstruct(val)
				error('Need to pass a colorbar struct or file path.')
			end
			
			ui.overlays(o).cbar = val;
			
			% set popup of cmap list to 'user'
			str = get(ui.overlays(o).cmapPopup, 'String');
			set(ui.overlays(o).cmapPopup, 'Value', length(str));			

        case {'colormap' 'cmap'}    % N x 3 color map for overlay
            if ischar(val) 
                list = mrvColorMaps;
                ii = cellfind(list, val);
                if isempty(ii)
                    error('cmap name not in list in mrvColorMaps.');
                end
                set(ui.overlays(o).cmapPopup, 'Value', ii);
                val = mrvColorMaps(val);

            else
                % set popup of cmap list to 'user'
                str = get(ui.overlays(o).cmapPopup, 'String');
                set(ui.overlays(o).cmapPopup, 'Value', length(str));
                
            end

            ui.overlays(o).cbar.cmap = val;
            
        case {'clim', 'clipmode'}   % color limits for color bar
            ui.overlays(o).cbar.clim = val;
            ui.overlays(o).clim = val;
            if isnumeric(val)
                set(ui.overlays(o).climPopup, 'Value', 2);           
                set(ui.overlays(o).climMin, 'String', num2str(val(1)));
                set(ui.overlays(o).climMax, 'String', num2str(val(2)));
            else
                set(ui.overlays(o).climPopup, 'Value', 1);           
            end
            
        case {'mapname'}
            ui.maps( ui.overlays(o).mapNum ).name = val;
            
        case {'dataunits' 'mapunits'}
            ui.maps( ui.overlays(o).mapNum ).dataUnits = val;
            
        case {'hide'}
            ui.overlays(o).hide = val;
            
            if checkfields(ui, 'overlays', 'hideCheck') & ...
                    ishandle(ui.overlays(o).hideCheck)
                set(ui.overlays(o).hideCheck, 'Value', val);
            end
                
            
        otherwise           % just directly assign the field
            ui.overlays(o).(param) = val;
    end
end

mrViewRefresh(ui);

return
% /-------------------------------------------------------------------/ %




% /-------------------------------------------------------------------/ %
function ui = setOverlayFromUI(ui, o);
% Parse uicontrols in overlay panel, 
% use this info to adjust overlay settings
% in the ui struct's overlays field for the o-th
% overlay,  and ensure the uicontrols are internally
% consistent.
% ras 08/05
S = ui.overlays(o); % overlay sub-struct

% get hide state
S.hide = logical(get(S.hideCheck, 'Value'));

% get map to display as overlay
S.mapNum = get(S.mapPopup, 'Value');

% get colormap to use
if isequal(gcbo, S.cmapPopup)   % do only if user selected the cmap
    cmap = get(S.cmapPopup, 'Value');
    S.cbar.cmap = mrvColorMaps(cmap);
end

% get colormap limits (clim) from controls
if get(S.climPopup, 'Value')==1
    % auto-scale,  scaling values to fit what's displayed
    S.clim = 'auto';
    
    % also ensure these guys are invisible:
    set(S.climMin, 'Visible', 'off');
    set(S.climMax, 'Visible', 'off');
    set(S.climText, 'Visible', 'off');
else
    % manually set: get vals from edit fields
    a = get(S.climMin, 'String');
    b = get(S.climMax, 'String');
    S.clim = [str2num(a) str2num(b)];
    
    % also ensure these guys are visible:
    set(S.climMin, 'Visible', 'on');
    set(S.climMax, 'Visible', 'on');
    set(S.climText, 'Visible', 'on');
end

% evaluate threshold settings
for i = 1:3
    S.thresholds(i).on = get(S.threshCheck(i), 'Value');
    if S.thresholds(i).on,  
        vis = 'on';
    else,  
        vis = 'off';
    end

    % get previous slider range,  for min/max check below
    oldRng(1) = get(S.threshMax(i).sliderHandle, 'Min');
    oldRng(2) = get(S.threshMax(i).sliderHandle, 'Max');
 
	% update the index of the map to be used for this threshold
    m = get(S.threshMap(i), 'Value');
    S.thresholds(i).mapNum = m;

	% grab the current threshold values:
	S.thresholds(i).min = get(S.threshMin(i).sliderHandle, 'Value');
    S.thresholds(i).max = get(S.threshMax(i).sliderHandle, 'Value');

	% update properties of thresh controls
    set(S.threshMap(i), 'Visible', vis, 'String', {ui.maps.name});    
    mrvSliderSet(S.threshMax(i), 'Range', ui.maps(m).dataRange, 'Visible', vis);
    mrvSliderSet(S.threshMin(i), 'Range', ui.maps(m).dataRange, 'Visible', vis);

	% if min or max were set to the extreme ends of the range
    % before,  make sure they stay that way now (by setting to the
	% min / max of the new range)
    if S.thresholds(i).min==oldRng(1) || ...
			S.thresholds(i).min > ui.maps(m).dataRange(2)
		S.thresholds(i).min = ui.maps(m).dataRange(1);
    end
    if S.thresholds(i).max==oldRng(2) || ...
			S.thresholds(i).min < ui.maps(m).dataRange(1)
		S.thresholds(i).max = ui.maps(m).dataRange(2);
	end
	
	% having completed the range check (which updates in case a new
	% thresholding map was selected),
	% update the values in the GUI to match the stored settings
	mrvSliderSet(S.threshMin(i), 'Value', S.thresholds(i).min);	
    mrvSliderSet(S.threshMax(i), 'Value', S.thresholds(i).max);
end

% turn on 'time' slider, if needed
if ndims(ui.maps(S.mapNum).data) >= 4
    m = S.mapNum;
    nVols = size(ui.maps(m).data, 4);
    if length(ui.maps(m).dimUnits) >= 4 & ~isempty(ui.maps(m).dimUnits{4})
        label = ui.maps(m).dimUnits{4};
    else
        label = 'Subvolume';
    end
    mrvSliderSet(ui.overlays(o).time, 'Visible', 'on', 'Range', [1 nVols], ...
                   'Label', label);
    S.subVol = get(ui.overlays(o).time.sliderHandle, 'Value');
else
    mrvSliderSet(ui.overlays(o).time, 'Visible', 'off');
    S.subVol = 1;
end


set(S.mapPopup, 'String', {ui.maps.name});    

ui.overlays(o) = S;

return