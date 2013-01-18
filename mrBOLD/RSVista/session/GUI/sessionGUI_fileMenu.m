function GUI = sessionGUI_fileMenu(GUI)
% Attach a File Menu to the session GUI figure, including
% callbacks for all file-related operations.
%
% GUI = sessionGUI_fileMenu(GUI);
%
%
% ras, 07/06.
GUI.menus.file = uimenu('Label', 'File', 'Separator', 'on');

% Attach submenus
submenu_study(GUI.menus.file);
submenu_session(GUI.menus.file);

uimenu(GUI.menus.file, 'Label', 'Quit', 'Separator', 'on', ...
          'Callback', 'sessionGUI_close;');
return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = submenu_study(parent)
% attach a submenu for Study-related operations.
h = uimenu(parent, 'Label', 'Study', 'Separator', 'off');

uimenu(h, 'Label', 'New Study', 'Separator', 'off', ...
          'Callback', 'sessionGUI_addStudy;');

  uimenu(h, 'Label', 'Remove Study', 'Separator', 'off', ...
          'Callback', 'sessionGUI_removeStudy;');
      
return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function h = submenu_session(parent)
% attach a submenu for Study-related operations.
h = uimenu(parent, 'Label', 'Session', 'Separator', 'off');

uimenu(h, 'Label', 'Add Session To Study', 'Separator', 'off', ...
          'Callback', 'sessionGUI_addSession;');

uimenu(h, 'Label', 'Remove Session from Study', 'Separator', 'off', ...
          'Callback', 'sessionGUI_removeSession;');

uimenu(h, 'Label', 'Initialize New Session', 'Separator', 'on', ...
          'Callback', 'cd(sessionSelectDialog); mrInitRet;');


return
