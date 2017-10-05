function GUI = sessionGUI_statusPanel(GUI);
%
% GUI = sessionGUI_statusPanel(GUI);
%
% Attach a panel to the Session GUI containing an embedded mrvWaitbar,
% an 'on/off' light to signify the busy state (GUI is executing callbacks),
% and an edit field to run command line commands. This is intended to
% prevent having to have the command window showing in the background to
% see if the GUI is busy or not, and run code.
%
% ras, 07/06.
GUI.panels.status = mrvPanel('below', 4, GUI.fig, 'char');

% add axes for on/off light, mrvWaitbar

% add command line callback
uicontrol('Parent', GUI.panels.status, 'Style', 'edit', 'String', '', ...
    'Units', 'char', 'Position', [40 0 100 2], 'BackgroundColor', 'w', ...
    'FontSize', 9, 'HorizontalAlignment', 'left', ...
    'Callback', 'eval(get(gcbo, ''String'')); ');

% add text for feedback messages
h = uicontrol('Parent', GUI.panels.status, 'Style', 'text', 'String', '', ...
    'Units', 'char', 'Position', [1 2 100 2], 'BackgroundColor', [.9 .9 .9], ...
    'HorizontalAlignment', 'left', 'FontSize', 9, 'FontWeight', 'bold', ...
    'Callback', 'eval(get(gcbo, ''String'')); ');
GUI.controls.feedback = h; 


set(GUI.panels.status, 'BackgroundColor', [.9 .9 .9], 'Units', 'normalized');

% initialize to off
mrvPanelToggle(GUI.panels.status, 'off');

return
