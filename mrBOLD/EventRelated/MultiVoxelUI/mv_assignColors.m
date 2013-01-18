function mv = mv_assignColors(mv);
% mv = mv_assignColors(mv);
%
% Assign a color order to an time course UI, 
% saving the results to the event-related parameters.
%
% 09/05 ras.
if ieNotDefined('trials')
   mv = get(gcf,'UserData');
end

mv.trials = er_assignColors(mv.trials);

% update and save the colors in the event-related parameters
mv.params.condColors = mv.trials.condColors;
hI = initHiddenInplane;
params = er_getParams(hI,mv.params.scans(1),mv.params.dataType);
params.condColors = mv.params.condColors;
er_setParams(hI,params,mv.params.scans,mv.params.dataType);


set(mv.ui.fig,'UserData',mv);
MultiVoxelUI;

return
