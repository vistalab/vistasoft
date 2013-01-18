function ui = mrViewRemoveOverlay(ui,o);
%
% ui = mrViewRemoveOverlay([ui],[o]);
% 
% Close/remove an overlay from a mrViewer UI.
% o is the index into the overlay; if omitted
% it removes the last overlay.
%
% ras 07/05.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet;            end
if ~exist('o','var') | isempty(o), o = length(ui.overlays);     end

% new overlay order
newInd = setdiff(1:length(ui.overlays),o);

% close the UI panel if it exists
if checkfields(ui,'panels','overlays') & ishandle(ui.panels.overlays(o))
    % first check if it's in its own window: if it is, close the 
    % window too
    pos = get(ui.panels.overlays(o),'Position');
    if isequal(pos,[0 0 1 1])
        par = get(ui.panels.overlays(o),'Parent'); 
        delete(par);              
    else
        mrvPanelToggle(ui.panels.overlays(o),'off');
        delete(ui.panels.overlays(o));
    end
end

% remove the menu option to toggle this overlay
if checkfields(ui,'menus','overlayToggle') & ...
   ishandle(ui.menus.overlayToggle(o))
    delete(ui.menus.overlayToggle(o));
    ui.menus.overlayToggle = ui.menus.overlayToggle(newInd);
end

% remove the overlay field
ui.overlays = ui.overlays(newInd);

ui = mrViewRefresh(ui);

return


