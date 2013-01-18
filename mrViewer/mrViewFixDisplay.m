function ui = mrViewFixDisplay(ui);
%
% ui = mrViewFixDisplay(ui);
%
% Fixes the graphic glitches in the mrViewer display panel.
% A quick fix for bugs in docking/undocking panels.
%
% ras 10/2006.
if ~exist('ui', 'var') | isempty(ui),  ui = mrViewGet; end
if ishandle(ui),     ui = get(ui, 'UserData');         end

% % a heuristic: make sure the accessory panels attached to the left and
% % right of the main figure have the same width (somehow the toggling
% % doesn't quite prevent the panels from shrinking):
% tmp = [ui.panels.nav ui.panels.mesh ui.panels.info ui.panels.overlays];
% pos = get(tmp, 'Position');  N = length(pos);
% pos = reshape( [pos{:}], [4 N] )';
% widths = pos(:,3);
% for n = 1:N
% 	pos(n,3) = 0.1; %mean(widths);
% 	set(tmp(n), 'Position', pos(n,:));
% end


% find panels which are both visible and attached to the main figure,
% and hide them for a bit
panels = [ui.panels.colorbar ui.panels.nav ui.panels.grayscale ui.panels.roi ...
          ui.panels.info ui.panels.mesh ui.panels.overlays];

attached = [];

for h = panels
   if ishandle(h) & get(h,'Parent')==ui.fig & isequal(get(h,'Visible'), 'on')
       attached = [attached h];
   end
end

for h = attached
    mrvPanelToggle(h, 'off');
end
    

% maximize the main display
set(ui.panels.display, 'Position', [0 0 1 1]);

% un-hide the panels that were there
for h = attached
    mrvPanelToggle(h, 'on');
end

centerfig(ui.fig, 0);

return
