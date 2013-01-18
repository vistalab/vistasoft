function ui = mrViewColorbarPanel(ui, dockFlag, vis);
% Create a new colorbar for a mrViewer UI, associated with the 
% overlay index o.
%
% ui = mrViewColorbarPanel(ui, <dockFlag=1>, <vis=0>);
%
% dockFlag: if 1,  will attach panel to the 
% mrViewer figure. Otherwise,  will make a 
% separate figure for the panel.
%
% vis: if 0, will initialize the panel to be hidden (default when
% starting up mrViewer); otherwise, leave it visible (as when 
% docking/undocking the panel).
%
% ras, 12/2006.
if ~exist('ui', 'var') | isempty(ui), ui = mrViewGet; end
if ~exist('dockFlag', 'var') | isempty(dockFlag),  dockFlag = 0; end
if ~exist('vis', 'var') | isempty(vis),  vis = 0; end

%%%%%%%%%%%%%%%%%%%%
% Create the panel %
%%%%%%%%%%%%%%%%%%%%
if dockFlag==1
	ui.panels.colorbar = mrvPanel('below', 80, ui.fig, 'pixels');
else
    hfig = figure('Name', sprintf('Colorbar [%s]', ui.tag), ...
                  'Units', 'normalized', ...
                  'Position', [0 .23 .12 .1], ...
                  'MenuBar', 'none', ...
                  'NumberTitle', 'off', ...
                  'UserData', ui.tag);              
    ui.panels.colorbar = uipanel('Parent', hfig, 'Units', 'normalized', ...
                               'Position', [0 0 1 1]);

	% set the close request function such that closing this window actually
	% just toggles its visibility w/o destroying it
    crf = 'ui = mrViewGet; ';
    crf = [crf 'mrvPanelToggle(ui.panels.colorbar);'];
    set(hfig, 'CloseRequestFcn', crf);
end

bgColor = [.9 .9 .9];
fgColor = [0 0 0];
set(ui.panels.nav, 'BackgroundColor', bgColor, ...
    'ShadowColor', bgColor, 'Title', '');

set(ui.panels.colorbar, 'BackgroundColor', 'w', 'ShadowColor', 'w', ...
    'Parent', ui.fig, 'Units', 'normalized');

%%%%% create a ui context menu, which will attach to the colorbar panel
% this will let me toggle the color scheme of the colorbars (useful 
% for making figures)
ui.controls.cbarPanelMenu = uicontextmenu;

cb = ['TMP = umtoggle(gcbo); '...
	  'mrViewSet(gcf, ''CbarColorScheme'', TMP+1); clear TMP; ' ...
	  'mrViewColorbar(gcf); '];
uimenu(ui.controls.cbarPanelMenu, 'Label', 'White Color Scheme', ...
	   'Callback', cb);
   
set(ui.panels.colorbar, 'UIContextMenu', ui.controls.cbarPanelMenu)


%%%%% create a ui context menu, which will attach to each colorbar
% This menu will allow quick access to editing, loading, and saving
% functions for the colorbars. 
ui.controls.cbarContextMenu = uicontextmenu;

% edit cbar
cb =  'mrViewEditCbar(gcf, get(gca, ''UserData'')); ';
uimenu(ui.controls.cbarContextMenu, 'Label', 'Edit...', 'Callback', cb);

% load saved cbar
cb = 'mrViewSetOverlay(gcf, ''cbar'', cbarLoad(), get(gca, ''UserData'')); ';
uimenu(ui.controls.cbarContextMenu, 'Label', 'Load...', 'Callback', cb);

% save cbar
cb = 'cbarSave(mrViewGet(gcf, ''cbar'', get(gca, ''UserData''))); ';
uimenu(ui.controls.cbarContextMenu, 'Label', 'Save...', 'Callback', cb);

% save as preset cbar
cb = 'cbarSavePreset(mrViewGet(gcf, ''cbar'', get(gca, ''UserData''))); ';
uimenu(ui.controls.cbarContextMenu, 'Label', 'Save Preset...', 'Callback', cb);

% also scan for preset color bars which may have been saved
% this will allow for quick reload of complex user-defined cbars
cbarPresetMenus(ui.controls.cbarContextMenu, ui.fig);

%%%%%hide the panel if requested
if vis==0
	mrvPanelToggle(ui.panels.colorbar, 'off');    
end
return
