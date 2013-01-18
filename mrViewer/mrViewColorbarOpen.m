function ui = mrViewColorbarOpen(ui, o, cmap);
% Create a new colorbar for a mrViewer UI, associated with the 
% overlay index o.
%
% ui = mrViewColorbarOpen(ui, o, <cmap='hot'>);
%
% The optional 'cmap' argument specifies an initial colormap for the new
% colorbar (defaults to 'hot').
%
%
% ras, 12/2006.
if ~exist('ui', 'var') | isempty(ui), ui = mrViewGet; end
if ~exist('o', 'var') | isempty(o), o = length(ui.overlays); end
if ~exist('cmap', 'var') | isempty(cmap), cmap = 'hot'; end

ui.overlays(o).cbar = cbarDefault( mrvColorMaps(cmap) );                           
ui.panels.colorbars(o) = mrvPanel('below', 80, ui.fig, 'pixels');
set(ui.panels.colorbars(o), 'BackgroundColor', 'k', 'ShadowColor', 'k', ...
    'Parent', ui.fig, 'Units', 'normalized');

% give the colorbar a context menu, allowing the user to edit the cmap:
ui.overlays(o).contextMenu = uicontextmenu('Parent', ui.fig);

ui.overlays(o).cbarAxes = axes('Parent', ui.panels.colorbars(o), ...
                           'Position', [.15 .7 .7 .25], ...
                           'XColor', 'w', 'YColor', 'w', ...
                           'UIContextMenu', ui.overlays(o).contextMenu);                       

% edit cbar
cb = sprintf('mrViewEditCbar(gcf, %i); ', o);
uimenu(ui.overlays(o).contextMenu, 'Label', 'Edit...', 'Callback', cb);

% load saved cbar
cb = sprintf('mrViewSetOverlay(gcf, ''cbar'', cbarLoad(), %i); ', o);
uimenu(ui.overlays(o).contextMenu, 'Label', 'Load...', 'Callback', cb);

% save cbar
cb = sprintf('cbarSave(mrViewGet(gcf, ''cbar'', %i)); ', o);
uimenu(ui.overlays(o).contextMenu, 'Label', 'Save...', 'Callback', cb);

% save as preset cbar
cb = sprintf('cbarSavePreset(mrViewGet(gcf, ''cbar'', %i)); ', o);
uimenu(ui.overlays(o).contextMenu, 'Label', 'Save Preset...', 'Callback', cb);

%% also scan for preset color bars which may have been saved
% this will allow for quick reload of complex user-defined cbars
cbarPresetMenus(ui.overlays(o).contextMenu, ui.fig, o);

ui = mrViewSetOverlay(ui, ui.panels.overlays(o));      

return
