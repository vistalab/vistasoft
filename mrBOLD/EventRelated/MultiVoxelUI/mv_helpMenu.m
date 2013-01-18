function mv = mv_helpMenu(mv, hfig);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add menus (5): help menu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mv.ui.helpMenu = uimenu(hfig, 'ForegroundColor', [.6 .2 0], 'Label', 'Help', ...
                              'Separator', 'on');

% web page callback:
% web http://white.stanford.edu/newlm/index.php/Multi_Voxel_UI
cb = 'web http://white.stanford.edu/newlm/index.php/Multi_Voxel_UI';
mv.ui.webHelp = uimenu(mv.ui.helpMenu, 'Label', 'Time Course UI page', 'Separator', 'off', ...
    'CallBack', cb);

% web page (external browser) callback:
% web http://white.stanford.edu/newlm/index.php/Multi_Voxel_UI -browser
cb = 'web http://white.stanford.edu/newlm/index.php/Multi_Voxel_UI -browser';
cb = 'web http://white/newlm/index.php/Main_Page -browser';
mv.ui.webHelp2 = uimenu(mv.ui.helpMenu, 'Label', 'Time Course UI page (external browser)', 'Separator', 'off', ...
    'CallBack', cb);


% mrVista web page callback:
% web web http://white.stanford.edu/newlm/index.php/Main_Page
cb = 'web http://white.stanford.edu/newlm/index.php/Main_Page';
mv.ui.webWiki = uimenu(mv.ui.helpMenu,  'Label',  'mrVista wiki',  ...
    'Separator',  'off',  'Callback',  cb);

% mrVista web page (external browser) callback:
% web web http://white.stanford.edu/newlm/index.php/Main_Page
% -browser
mv.ui.webWiki2 = uimenu(mv.ui.helpMenu,  'Label',  'mrVista wiki (external browser)',  ...
    'Separator',  'off',  'Callback',  cb);

% identify callback for menu item
cb = 'helpFindCallback; ';
uimenu(mv.ui.helpMenu,  'Label',  'Identify Callback for a menu item',  ...
        'Separator',  'on',  'Callback',  cb);

return