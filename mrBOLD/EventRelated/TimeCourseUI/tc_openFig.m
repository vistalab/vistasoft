function tc = tc_openFig(tc);
% tc = tc_openFig(tc);
%
% For timeCourseUI (mrLoadRet):
% opens up the time course figure, plus initializes
% the tc struct, which contains all the information
% necessary for plotting and which resides as the 
% figure's user data. This involves a certain degree
% of parsing what sort of design experiment it was: 
% e.g., is it a cyclical experiment, an ABAB alternating-block
% experiment, or an event-related/unpredictable block experiment where 
% the trial/block order is specified in a parfile? 
%
% uses meanTSeries to get time course data -- which only makes sense, but
% should be noted. Will therefore use whatever detrend/inhomo
% correct/temporal normalization options have been selected and stored in
% the dataTYPES struct of the mrSESSION file.
%
% 02/23/04 ras: broken off as a separate function from timeCourseUI (now renamed
% timeCourseUI).
% 03/11/04 ras: added an ability to merge null (0 condition) trials into
% the next trial, if the trial design was alternating null/non-null (as is
% the case for Kalanit's AdaptNSelect, and Bob/Michal's reading expts). 
% 07/04 ras: renamed tc_openFig; now calls on er_chopTSeries to get 
% a bunch of fields at once (not just the concatenated mean tSeries). 
% Also cleaned up the tc structure significantly.
% 03/06 ras: now uses uipanel tools (and mrvPanel function) to create 
% a separate uipanel for the legend and plot displays; mrvPanelToggle
% toggles it on/off.
mrGlobals;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% open figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figName = sprintf('%s Time Course  [%s %s %s]',...
                   tc.roi.name, tc.params.sessionCode, ...
                   tc.params.dataType, num2str(tc.params.scans));,

tc.ui.fig = figure('Name', figName, ...
           'Units', 'Normalized', ...
           'Position', [0 .56 .5 .34], ...
           'NumberTitle', 'off', ...
           'Tag', 'TimeCourseUI', ...
           'Color', 'w'); % [0 0.56 0.8 0.34],...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create subpanels for plot display, legend; add menus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% main panel for plots
tc.ui.plot = uipanel('Units', 'Normalized', 'Position', [0 0 1 1],...
                    'BackgroundColor', 'w', 'FontSize', 12, ...
                    'BorderType', 'none', 'Parent', tc.ui.fig);

                    
% add menus
tc = tc_addMenus(tc, tc.ui.fig);

% create, populate legend panel
tc = tc_legend(tc, 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set tc struct as userdata of fig
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(gcf,'UserData',tc);

timeCourseUI;

return

