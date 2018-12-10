function vw = helpMenu(vw, topic)
% [vw or menu handle] = helpMenu([vw], [topic]);
%
% Attach a menu containing help-related callbacks to a mrVista view or
% other figure.
%
% If a view is provided, attaches the menu to that view and returns
% the modified view structure. If no args are provided, attaches the
% help menu to the current figure and returns a handle to the menu.
%
% The optional 'topic' argument lets you specify an additional topic on the
% VISTA wiki. If specified, the menu will contain shortcuts to that wiki
% page (if it exists).
%
% ras, 11/07/05.

% a mrVista view shouldn't be required for this stuff; but if one
% is provided, make the main figure current, so the menus are attached
% to that figure:
if exist('vw','var') && ~isempty(vw)
    figure(vw.ui.figNum);
end

if notDefined('topic'),		topic = '';				end

% create the top-level menu
hmenu = uimenu(gcf, 'Label', 'Help', 'Separator', 'on');

% call up VISTASOFT home page:
cb = 'web http://white.stanford.edu/newlm';
uimenu(hmenu, 'Label', 'VISTASOFT Home / Wiki', 'Callback', cb);

% call up VISTASOFT home page:
cb = 'web(''http://white.stanford.edu/newlm'', ''-browser''); ';
uimenu(hmenu, 'Label', 'VISTASOFT Home / Wiki (external browser)', 'Callback', cb);

% call up mrVista home page:
cb = 'web http://white.stanford.edu/newlm/index.php/MrVista';
uimenu(hmenu, 'Label', 'mrVista Home / Wiki', 'Callback', cb);

% call up mrVista home page:
cb = 'web(''http://white.stanford.edu/newlm/index.php/MrVista'', ''-browser''); ';
uimenu(hmenu, 'Label', 'mrVista Home / Wiki (external browser)', 'Callback', cb);

if ~isempty(topic)
	% call up topic page:
	cb = sprintf('web http://white.stanford.edu/newlm/index.php/%s', topic);
	label = sprintf('%s wiki page', topic);
	uimenu(hmenu, 'Label', label, 'Separator', 'on', 'Callback', cb);
	
	% call up topic page (external browser):
	cb = sprintf('web http://white.stanford.edu/newlm/index.php/%s -browser', topic);
	label = sprintf('%s wiki page (external browser)', topic);
	uimenu(hmenu, 'Label', label, 'Callback', cb);
end

%% identify the callback to a menu item:
uimenu(hmenu, 'Label', 'Identify Callback for a Menu Item', ...
    'Separator', 'on', 'Callback', 'helpFindCallback;');


%% if no view provided, return a handle to the menu
if notDefined('vw')
    vw = hmenu;
end

return
