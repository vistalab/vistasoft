function sessionGUI_close;
% Close a Session GUI, clearing the relevant global variables along the
% way. 
%
% sessionGUI_close;
%
% ras, 07/06
mrGlobals2;

% close any subsidiary viewers
for v = GUI.viewers
    mrViewClose(v);
end

% close the main figure
delete(GUI.fig);

INPLANE{1} = [];
VOLUME{1} = [];
if isempty(cellfind(INPLANE)), INPLANE = {}; end
if isempty(cellfind(VOLUME)), VOLUME = {}; end


% Check if there are no more open views: if not, clean the workspace
if isempty(cellfind(INPLANE)) & isempty(cellfind(VOLUME)) 
    mrvCleanWorkspace;
end

clear global GUI;

return
