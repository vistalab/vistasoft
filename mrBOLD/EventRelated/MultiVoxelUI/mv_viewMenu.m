function mv = mv_viewMenu(mv,hfig);
%
% mv = mv_viewMenu(mv,hfig);
%
% Add menus with view options for
% the MultiVoxel UI.
%
%
% ras, 04/05
if ieNotDefined('hfig')
    hfig = gcf;
end

if ieNotDefined('mv')
    mv = get(hfig,'UserData');
end

mv.ui.viewMenu = uimenu('ForegroundColor', 'k', 'Label', 'View', 'Separator', 'on');

addFigMenuToggle(mv.ui.viewMenu);

% sort by omniR option
uimenu(mv.ui.viewMenu,'Label','New MultiVoxel UI Window',...
   'Separator','on','Callback','mv_openFig(get(gcf,''UserData'')); multiVoxelUI;');


set(hfig,'UserData',mv);

return