function ui = mrViewHelpMenu(ui);
%
% ui = mrViewHelpMenu(ui);
%
% Attaches a help menu to a mrViewer UI. 
%
% ras 12/06.
if ~exist('ui', 'var') | isempty(ui),  ui = get(gcf, 'UserData'); end

ui.menus.help = uimenu(ui.fig, 'Label', 'Help');


% call up VISTA software home page:
cb = 'web http://white.stanford.edu/newlm';
uimenu(ui.menus.help, 'Label', 'mrVista Home / Wiki', 'Callback', cb);

% call up VISTA software home page (external browser):
cb = 'web(''http://white.stanford.edu/newlm'', ''-browser''); ';
uimenu(ui.menus.help, 'Label', 'mrVista Home / Wiki (external browser)', 'Callback', cb);

% call up mrViewer home page:
cb = 'web http://white.stanford.edu/newlm/index.php/MrViewer';
uimenu(ui.menus.help, 'Label', 'mrViewer Help', 'Callback', cb, 'Separator', 'on');

% call up mrViewer home page (external browser):
cb = 'web(''http://white.stanford.edu/newlm/index.php/MrViewer'', ''-browser''); ';
uimenu(ui.menus.help, 'Label', 'mrViewer Help (external browser)', 'Callback', cb);

% identify the callback to a menu item:
uimenu(ui.menus.help, 'Label', 'Identify Callback for a Menu Item', ...
    'Separator', 'on', 'Callback', 'helpFindCallback;');

return
