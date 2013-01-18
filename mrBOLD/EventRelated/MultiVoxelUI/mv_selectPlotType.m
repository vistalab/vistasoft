function mv = mv_selectPlotType(type);
%
% mv = mv_selectPlotType(type);
%
% Set the Multi Voxel UI to plot the selected plot
% type. 
% 
% Default types are:
% 1) Plot the whole time courses for each voxel, after
%    detrending/preprocessing.
% 2) Plot the time courses for each trial and condition,
%    averaged across voxels.
% 3) Plot the time courses for each voxel and condition,
%    averaged across trials.
% 4) Plot the mean amplitudes for each voxel and condition,
%    averaged across trials.
% 5) Plot the mean amplitudes for each trial, voxel, and condition.
% 6) d' histograms [n. y. i.]
% 7) Visualize GLMs for each voxel (w/ slider to page between voxels)
%
% ras, 04/05.
mv = get(gcf,'UserData');
mv.ui.plotType = type;
set(gcf, 'UserData', mv);

% clear previous objects in the figure
old = findobj('Type', 'axes', 'Parent', gcf);
old = [old; findobj('Type', 'uicontrol', 'Parent', gcf)];
old = [old; findobj('Tag', 'GLM Display Panel', 'Parent', gcf)];
delete(old);

% hide GLM control panel if we're not visualizing this
if type ~= 7    
    mrvPanelToggle(mv.ui.glmPanel, 'off');
end

% make only the selected option checked
if checkfields(mv, 'ui', 'plotHandles')
    set(mv.ui.plotHandles, 'Checked', 'off')
    set(mv.ui.plotHandles(type), 'Checked', 'on');
end

% multiVoxelUI;

return
