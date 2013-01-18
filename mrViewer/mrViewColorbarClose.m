function ui = mrViewColorbarClose(ui, o);
% Close a colorbar in a mrViewer UI (for the overlay index o).
%
% ui = mrViewColorbarClose(ui, <o=last overlay>);
%
%
%
% ras, 12/2006.
if ~exist('ui', 'var') | isempty(ui), ui = mrViewGet; end
if ~exist('o', 'var') | isempty(o), o = length(ui.overlays); end

delete(ui.panels.colorbars(o));

return