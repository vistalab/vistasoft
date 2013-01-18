function mv = mv_xformMenu(mv,hfig);
%
% mv = mv_xformMenu(mv,hfig);
%
% Make a menu for transforming data from
% a multi-voxel UI to other views/objects.
%
%
% ras 05/05.
if ieNotDefined('hfig')
    hfig = gcf;
end

if ieNotDefined('mv')
    mv = get(hfig,'UserData');
end

mv.ui.xformMenu = uimenu('ForegroundColor',[0.3 0 1],'Label','Xform','Separator','on');

% xform ROI option (odd v even trials)
uimenu(mv.ui.xformMenu,'Label','ROI -> mrVista view',...
       'Separator','off','Callback','mv_makeRoi;');
   
% xform map option
uimenu(mv.ui.xformMenu,'Label','Parameter -> mrVista map',...
       'Separator','off','Callback','mv_exportMap;');
       
% dump data to workspace option
uimenu(mv.ui.xformMenu,'Label','Dump Data to Workspace',...
   'Separator','on','Callback','tc_dumpDataToWorkspace;');

   
set(hfig,'UserData',mv);

return
