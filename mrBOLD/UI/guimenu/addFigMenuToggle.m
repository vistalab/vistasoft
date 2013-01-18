function h = addFigMenuToggle(parent);
%
% h = addFigMenuToggle([parent]);
%
% Add to the parent menu/object a uimenu
% enabling the user to toggle on/off the
% figure menu bar.
%
% Many VISTASOFT programs turn this menu
% off by default to keep windows from
% getting cluttered with menus. But these
% menus do contain many useful tools, such
% as zoom options, editing the figure, and
% export tools to various formats. So,
% This menu lets the user easily turn the
% menus on/off.
%
% Returns a handle to the menu.
%
% ras 03/05.
if ieNotDefined('parent')
    parent = gcf;
end

% build up a callback for the menu item:
%  
% on = umtoggle(gcbo);
% if on,
%   set(gcf,'MenuBar','figure');
% else,
%   set(gcf,'MenuBar','none');
% end
cb = 'on = umtoggle(gcbo);';
cb = [cb 'if on, set(gcf,''MenuBar'',''figure''); '];
cb = [cb 'else, set(gcf,''MenuBar'',''none''); '];
cb = [cb 'end '];

% make the menu
h = uimenu(parent,'Label','Figure Menus','Separator','on',...
                  'Selected','off','Callback',cb);
                  
                  
return

