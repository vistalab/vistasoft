function ui = mrViewEditCmap(ui, o);
%
%  ui = mrViewEditCmap(ui, <o=1>);
%
% Edit the color map for a mrViewer overlay, using a GUI.
%
%
% ras, 08/06.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet;        end
if ishandle(ui), ui = get(ui, 'UserData'); end
if notDefined('o'), o = 1; end

if ~isfield(ui, 'overlays') | isempty(ui.overlays) | length(ui.overlays) < o
    error('Invalid overlay.')
end

%%%%%Get params
cmap = ui.overlays(o).cmap;
clim = ui.overlays(o).clim;
nC = size(cmap, 1);



return