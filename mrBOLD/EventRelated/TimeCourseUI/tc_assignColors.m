function tc = tc_assignColors(tc);
% tc = tc_assignColors(tc);
%
% Assign a color order to an time course UI, 
% saving the results to the event-related parameters.
%
% 01/04 ras.
% 09/05 ras: moved the dialog to er_assignColors; now updates
% fields in tc.trials rather than tc itself, and saves the
% colors to the event-related params.
if ieNotDefined('trials')
   tc = get(gcf,'UserData');
end

tc.trials = er_assignColors(tc.trials);

% update and save the colors in the event-related parameters
tc.params.condColors = tc.trials.condColors;
mrGlobals; callingDir = pwd; cd(HOMEDIR);
% hI = initHiddenInplane;
% params = er_getParams(hI, tc.params.scans(1), tc.params.dataType);
% params.condColors = tc.params.condColors;
% er_setParams(hI, params, tc.params.scans, tc.params.dataType);

tc_legend(tc); % update the legend w/ new colors

set(tc.ui.fig,'UserData',tc);
timeCourseUI;

cd(callingDir);

return
