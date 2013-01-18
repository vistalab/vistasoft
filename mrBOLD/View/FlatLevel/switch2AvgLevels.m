function view = switch2AvgLevels(view);
% view = switch2AvgLevels(view);
%
% For Flat across-levels views: switch
% the UI state to view the average 
% across gray levels.
%
% 08/31/04 ras.

ui = viewGet(view,'ui');
set(ui.level.sliderHandle,'Visible','off');
set(ui.level.labelHandle,'Visible','off');
set(ui.level.textHandle,'Visible','off');
set(ui.level.levelLabel,'Visible','off');
set(ui.level.numLevelLabel,'Visible','off');
set(ui.level.numLevelEdit,'Visible','off');
set(ui.levelButtons(1),'Value',1);

return