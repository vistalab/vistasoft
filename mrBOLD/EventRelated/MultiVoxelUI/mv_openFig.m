function [mv] = mv_openFig(mv);
% mv_openFig(view, voxels, scans, dt, ROIname);
%
% For MultiVoxel UI: Open the interface figure,  attaching
% menus and updating the mv data structure. (Use
% er_voxelData to get an mv structure from a mrVista
% ROI).
%
%
%
% ras,  04/05

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% open figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figName = sprintf('%s Voxel Data  [scans %s,  session %s]', ...
                   mv.roi.name, num2str(mv.params.scans), ...
                   mv.params.sessionCode);, 

mv.ui.fig = figure('Name', figName, ...
           'Units', 'Normalized', ...
           'Position', [0.2 0.4 0.4 0.4], ...
           'MenuBar', 'none', ...
           'NumberTitle', 'off', ...
           'Color', 'w');

% add menus
mv = mv_plotsMenu(mv, mv.ui.fig);
mv = mv_viewMenu(mv, mv.ui.fig);
mv = mv_analysisMenu(mv, mv.ui.fig);
mv = mv_settingsMenu(mv, mv.ui.fig);
mv = mv_xformMenu(mv, mv.ui.fig);
mv = mv_conditionsMenu(mv, mv.ui.fig);
mv = mv_helpMenu(mv, mv.ui.fig);

% add a control panel for visualizing GLMs (maybe other things too)
mv = mv_glmPanel(mv);

% clear axes
cla;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set mv struct as userdata of fig
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(mv.ui.fig, 'UserData', mv);


return


