function view = switch2SeparateLevels(view);
% view = switch2SeparateLevels(view);
%
% For Flat across-levels views: switch
% the UI state to view the gray levels
% separately
%
% 08/31/04 ras.

ui = viewGet(view,'ui');
set(ui.level.sliderHandle,'Visible','on');
set(ui.level.labelHandle,'Visible','on');
set(ui.level.textHandle,'Visible','on');
set(ui.level.levelLabel,'Visible','on');
set(ui.level.numLevelLabel,'Visible','on');
set(ui.level.numLevelEdit,'Visible','on');
set(ui.levelButtons(2),'Value',1);

return