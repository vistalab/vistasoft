function ui = mrViewColorbar(ui);
% Render colorbars for a mrViwer UI.
%
% ui = mrViewColorbar(ui);
%
% This function will draw the colorbars for all overlays in a mrViewer
% which are set to visible (i.e., the 'hide' setting is not set to 1). 
% The cbars will be placed horizontally along the colorbar panel.
% If not overlays are being shown, will ensure the colorbar panel is 
% hidden.
%
% ras, 02/2007.
if nargin<1, ui = mrViewGet; end
if ishandle(ui), ui = get(ui, 'UserData'); end

if isempty(ui.overlays)		% ensure panel is hidden
	if isequal(get(ui.panels.colorbar, 'Visible'), 'on')
		mrvPanelToggle(ui.panels.colorbar, 'off');
	end
	return
end

isHidden = [ui.overlays.hide];
overlayList = find(~isHidden);

if isempty(overlayList)		% ensure panel is hidden
	if isequal(get(ui.panels.colorbar, 'Visible'), 'on')
		mrvPanelToggle(ui.panels.colorbar, 'off');
	end
	return	
end

if isequal(get(ui.panels.colorbar, 'Visible'), 'off')
	mrvPanelToggle(ui.panels.colorbar, 'on');	
end

% delete old colorbars
delete(findobj('Parent', ui.panels.colorbar));

colors = 'kw'; % color schemes
col = colors(ui.settings.cbarColorScheme);

cbars = {ui.overlays(overlayList).cbar};
[hImgs hAxes] = cbarDrawMany(cbars, ui.panels.colorbar, col);

% enable context menus: attach the context menu to each colorbar, and
% set the overlay # as each axes' UserData, to point to the correct overlay
for i = 1:length(hImgs)
	o = overlayList(i);
	set(hAxes(i), 'UserData', o);
	set(hImgs(i), 'UIContextMenu', ui.controls.cbarContextMenu);
end

return
