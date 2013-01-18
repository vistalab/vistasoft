function ui = mrViewEditCbar(ui, o);
%
% ui = mrViewEditCbar(ui, o);
%
% Edit the colorbar for a given overlay in a mrViewer UI.
%
% ras, 08/2006.
if ~exist('ui','var') | isempty(ui),    ui = mrViewGet; end
if ishandle(ui), ui = get(ui, 'UserData'); end

if ~exist('o','var') | isempty(o)
    o = length(ui.overlays);
end

ui.overlays(o).cbar = cbarEdit(ui.overlays(o).cbar);

% if isfield(ui, 'fig') & ishandle(ui.fig)
%     set(ui.fig, 'UserData', ui);
% end

% update the cbar
mrViewRefresh(ui);

return
