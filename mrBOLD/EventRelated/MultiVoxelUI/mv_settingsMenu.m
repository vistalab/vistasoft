function mv = mv_settingsMenu(mv, hfig);
% mv = mv_settingsMenu(mv, hfig);
%
% Add a menu for adjusting multivoxel
% analysis settings in the MultiVoxel UI.
%
% ras,  04/05.
if ieNotDefined('hfig')
    hfig = gcf;
end

if ieNotDefined('mv')
    mv = get(hfig, 'UserData');
end

mv.ui.settingsMenu = uimenu('ForegroundColor', [0 0.5 0.7], 'Label', 'Settings', 'Separator', 'on');

% edit settings option
uimenu(mv.ui.settingsMenu, 'Label', 'Edit MultiVoxel Parameters', ...
   'Separator', 'off', 'Callback', 'mv_setParams;');

% edit event-related params option
uimenu(mv.ui.settingsMenu, 'Label', 'Edit Event-Related Parameters', ...
   'Separator', 'off', 'Callback', 'mv_editParams;');

% reorder conditions option
uimenu(mv.ui.settingsMenu, 'Label', 'Re-order conditions', ...
   'Separator', 'off', 'Callback', 'mv_reorderCondNums;');

% edit event-related params option
uimenu(mv.ui.settingsMenu, 'Label', 'Group Conditions', ...
   'Separator', 'off', 'Callback', 'mv_groupConditions;');



% edit condition colors option
cb = 'mv=get(gcf, ''UserData''); mv_assignColors(mv);';
uimenu(mv.ui.settingsMenu, 'Label', 'Assign Condition Colors', ...
   'Separator', 'off', 'Callback', cb);


set(hfig, 'UserData', mv);

return