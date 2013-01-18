function mv = mv_conditionsMenu(mv,hfig);
%
% mv = mv_conditionsMenu(mv,hfig);
%
% Add a menu for toggling on/off conditions
% in the multi voxel UI.
%
% ras, 04/05
% ras, 03/06: used to ignore baseline condition, now adds it.
if ieNotDefined('hfig')
    hfig = gcf;
end

if ieNotDefined('mv')
    mv = get(hfig,'UserData');
end

condNums = mv.trials.condNums;
condNames = mv.trials.condNames;
condColors = mv.trials.condColors;

% (callback will be as for the legend callback:
% umtoggle(gcbo);
% timeCourseUI; 
mv.ui.condMenu = uimenu('ForegroundColor', 'k', 'Label', 'Conditions', 'Separator', 'on');
accelChars = '0123456789-=';
cbStr=['umtoggle(gcbo); multiVoxelUI;'];
for i = 1:length(condNames)
    if i < length(accelChars)
        accel = accelChars(i);
    else
        accel = '';
    end
    if(isempty(mv.trials.condNames{i}))
        mv.trials.condNames{i}=num2str(i);
    end
    
    hc(i) = uimenu(mv.ui.condMenu,'Label',condNames{i},...
                     'Separator','off',...
                     'Checked','on',...
                     'Accelerator',accel,...
                     'Tag',num2str(condNums(i)),...
                     'UserData',condColors{i},'Callback',cbStr);
end

set(hc(1), 'Checked', 'off'); % unselect baseline condition

mv.ui.condMenuHandles = hc;           

set(hfig,'UserData',mv);

return