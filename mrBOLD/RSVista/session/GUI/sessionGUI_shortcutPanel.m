function GUI = sessionGUI_shortcutPanel(GUI);
%
% GUI = sessionGUI_shortcutPanel(GUI);
%
% Attach a panel to the Session GUI containing a set of 
% 'shortcut' buttons: buttons which can be flexibly assigned
% a callback according to the user's particular analyses / preferences.
%
% Each button, when created, is initially blank. Clicking on 
% one for the first time prompts the function assignShortcut, which
% lets the user specify MATLAB code as a callback, and a name for the
% button. The shortcut can be re-assigned by right-clicking on it
% and accessing a  uicontextmenu, which also calls assignShortcut. 
%
% The set of button shortcuts is saved for each mrVista2 repository
% in mrVista2/session/GUI/shortcuts.mat.
%
% ras, 07/06.
GUI.panels.shortcut = mrvPanel('right', 0.15);

set(GUI.panels.shortcut, 'BackgroundColor', [.9 .9 .9]);


% we'll make 6 buttons in a row
for i = 1:6
    % callback for initialized button / uimenu
    cb = sprintf('sessionGUI_assignShortcut(%i);',i);
    
    % create a context menu for each button
    cmenu = uicontextmenu;
    uimenu(cmenu, 'Label', 'Assign Button Callback...', ...
                  'Callback', cb);
    
    GUI.controls.shortcut(i) = uicontrol('Parent', GUI.panels.shortcut, ...
        'Style', 'pushbutton', 'String', '', 'Units', 'normalized', ...
        'Position', [.05 .97-i*.15 .9 .1], 'BackgroundColor', [.9 .9 .9], ...
        'UIContextMenu', cmenu, 'Callback',  cb);
end

% see if there's a saved shortcuts file; if so, set the saved values
loadPath = fullfile(fileparts(which(mfilename)), 'shortcuts.mat');
if exist(loadPath, 'file')
    load(loadPath, 'shortcuts')
    for j = 1:6
        set(GUI.controls.shortcut(j), 'String', shortcuts(j).string, ...
            'Callback', shortcuts(j).callback);
    end
end
        

% initialize to off
mrvPanelToggle(GUI.panels.shortcut, 'off');

return
