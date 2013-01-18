function ui = mrViewDock(ui, panel, state);
%  ui = mrViewDock(ui, panel, state);
%
% Attach / unattach a UI panel from a mrViewer display.
%
% ui: ui struct or handle to ui figure.
%
% panel: one of 'nav', 'roi', 'grayscale', 'info', 'mesh', or 'overlay'.
%
% state: either 'on', 'off', or a handle to a menu (in which case, will
% check / uncheck the menu, and set the state to the current
% checked value of that menu.)
%
% ras, 08/2006.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet; end
if ishandle(ui), ui = get(ui, 'UserData'); end
if nargin<3, help(mfilename); error('Not enough input args.'); end

% get the toggle state -- 1 for turning on, 0 for turning off
if ishandle(state)
    state = umtoggle(state);
elseif ischar(state)
    state = isequal(lower(state), 'on');
end


% we treat the 'overlay' case differently from others (because it
% may reflect more than one panel), so deal with that first:
if isequal(lower(panel), 'overlay')
    % this will follow the same logic as below
    if checkfields(ui, 'panels', 'overlays')

        for o = 1:length(ui.panels.overlays)
            vis = get(ui.panels.overlays(o), 'Visible');
            if isequal(vis, 'on')
                mrvPanelToggle(ui.panels.overlays(o), 'off');
            end
            
            delete(ui.panels.overlays(o));
			
            ui = mrViewOverlayPanel(ui, state, o);
            
            mrvPanelToggle(ui.panels.overlays(o), vis);
        end
        
    end
    
    set(ui.fig, 'UserData', ui);
    
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if we got here, we have one panel to toggle, and luckily,  %
% we can do this in a generalized manner:                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% determine whether panel is currently visible:
% if it is, toggle it to be invisible
p = lower(panel); % field name for panel

vis = get(ui.panels.(p), 'Visible');
if isequal(vis, 'on')
    mrvPanelToggle(ui.panels.(p), 'off');
end
        
% delete the old panel
delete(ui.panels.(p));

% re-initialize the panel in the new, docked/undocked state:
% (do this by evaluating a dynamic function call -- this will
% update the ui.panels.(p) field):
str = p; str(1) = upper(str(1)); 
cmd = sprintf('mrView%sPanel(ui, %i, 1); ', str, state);
ui = eval(cmd);
        
% set panel to match UI-specified visibility state:
mrvPanelToggle(ui.panels.(p), vis);

% stash the updated ui panel
set(ui.fig, 'UserData', ui);


return
