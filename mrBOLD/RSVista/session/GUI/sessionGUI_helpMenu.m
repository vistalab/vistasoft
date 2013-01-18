function GUI = sessionGUI_helpMenu(GUI);
% Attach a Help Menu to the session GUI figure.
%
% GUI = sessionGUI_helpMenu(GUI);
%
%
% ras, 07/06.
GUI.menus.help = uimenu('Label', 'Help', 'Separator', 'on');

cb = 'web http://white.stanford.edu/newlm';
uimenu(GUI.menus.help, 'Label', 'mrVista Home / Wiki', ...
       'Separator', 'off', 'Callback', cb);
   
cb = 'web http://white.stanford.edu/newlm -browser';
uimenu(GUI.menus.help, 'Label', 'mrVista Home / Wiki (external browser)', ...
       'Separator', 'off', 'Callback', cb);
       
uimenu(GUI.menus.help, 'Label', 'Identify Callback for a Menu Item', ...
        'Separator', 'on', 'Callback', 'helpFindCallback; ');
              
return

