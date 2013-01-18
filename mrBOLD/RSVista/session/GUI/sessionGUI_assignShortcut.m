function GUI = sessionGUI_assignShortcut(obj, label, callback);
% Assign the label and callback code for a Session GUI shortcut button.
%
% GUI = sessionGUI_assignShortcut([object or button #], <label>, <callback>);
%
% The first argument can be a handle to the button object, or the number
% (1-6) of the shortcut button. If the label or callback arguments are 
% omitted, pops up a dialog for them via assignShortcut.
%
% Saves the labels/callbacks for each mrVista2 installation in the file
% mrVista2/session/GUI/shortcuts.mat.
%
%
% ras, 07/06.
mrGlobals2;

if notDefined('obj'), obj = 1; end

if isnumeric(obj) & mod(obj, 1)==0 % get handle
    obj = GUI.controls.shortcut(obj);
end

if notDefined('label') | notDefined('callback')
    [label callback] = assignShortcut(obj);
end

% see if this is a GUI shortcut button: if so, save in the shortcuts file:
ii = find(GUI.controls.shortcut==obj);
if ~isempty(ii)
    savePath = fullfile(fileparts(which(mfilename)), 'shortcuts.mat');
    if exist(savePath, 'file')
        load(savePath, 'shortcuts');
    end
    for j = 1:6
        shortcuts(j).string = get(GUI.controls.shortcut(j), 'String');
        shortcuts(j).callback = get(GUI.controls.shortcut(j), 'Callback');
    end
    save(savePath, 'shortcuts');
end



return
