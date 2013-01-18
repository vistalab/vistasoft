function mv_singleVoxGlm(mv);
%
% mv_singleVoxGlm(mv);
%
% For a Multi Voxel UI, create an interface for visualizing GLM
% results for single voxels, and browsing through voxels.
%
% ras, 09/2006.
if notDefined('mv'), mv = get(gcf, 'UserData'); end
if ishandle(mv), mv = get(mv, 'UserData'); end

if checkfields(mv, 'ui', 'fig')
    fig = mv.ui.fig;
else, 
    fig = gcf;
end

% add a slider to the panel
nVoxels = size(mv.tSeries, 2);
mv.ui.glmVoxel = mrvSlider([.1 .8 .8 .1], 'Voxel', 'Parent', mv.ui.glmPanel, ...
                           'Range', [1 nVoxels], 'IntFlag', 1, ...
                           'MaxLabelFlag', 1, ...
                           'Callback', 'mv_visualizeGlm(gcf, round(val));');

% update the figure
set(fig, 'UserData', mv);

% Finally, do a visualization for Voxel 1:
mv_visualizeGlm(mv, 1, fig);


return
