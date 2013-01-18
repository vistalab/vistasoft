function mrViewClose(ui);
% Close a mrViewer UI, clearing the memory of the ui struct
% and closing all related windows.
%
% Usage:
% mrViewClose(ui);
%
% ras 07/15/05.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet; end
if ishandle(ui), ui = get(ui,'UserData'); end

% allow a tag to be passed in (as it is for the CloseRequestFcn
% for UI figs):
if ischar(ui), ui = get(findobj('Tag',ui),'UserData'); end

% find all figures pointing to this ui
h = findobj('Type','figure','UserData',ui.tag);
delete(h);

% For mrVista session viewing: check if there's a global GUI variable,
% and if so, remove this viewer from its list of open viewers
if ~isempty(findobj('Tag', 'mrVista Session GUI'))
    global GUI
    if ~isempty(GUI) & isfield(GUI, 'viewers') & ~isempty(GUI.viewers)
        ii = find(GUI.viewers==ui.fig);
        newRange = setdiff(1:length(GUI.viewers), ii);
        GUI.viewers = GUI.viewers(newRange);
        if GUI.settings.viewer==ii
            GUI.settings.viewer = length(GUI.viewers);
        end
    end
end

% also, close any mesh displays attached to this UI
if checkfields(ui, 'segmentation', 'mesh')
    for s = 1:length(ui.segmentation)
        for m = 1:length(ui.segmentation(s).mesh)
            if ui.segmentation(s).mesh{m}.id > 0
                mrmSet(ui.segmentation(s).mesh{m}, 'Close');
            end
        end
    end
    
elseif ~isempty(findobj('Tag', 'mrVista Session GUI'))
    % in this case, we're using the Session GUI, and may also
    % have a mesh attached to the VOLUME{1} view. Check for this,
    % and if so, close the mesh.
    global VOLUME
    if checkfields(VOLUME{1}, 'mesh')
        for m = 1:length(VOLUME{1}.mesh)
            mrmSet(VOLUME{1}.mesh{m}, 'Close');
        end
    end
    
end

% delete the main UI figure (don't close, since its 
% CloseRequestFcn is to call this, and can become
% horribly recursive).
delete(ui.fig);

% finally, there's a really bad tendency for the UI callbacks
% to dump the whole ui struct into the workspace. Although I 
% need to track down the culprits (some missing semicolon probably
% causes a callback to evaluate ui or ans), for now, go ahead and
% clear out the ans and ui variables, to prevent memory overflow:
evalin('base', 'clear ui ans');

return