function mv = mv_plotTrialTcs(mv);
%
% mv = mv_plotTrialTcs(mv);
%
% Plot nConditions subplots, each containing
% an image of the response during each trial,
% averaged across voxels.
%
% ras, 04/05
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end



% select this as the current plot type in the UI
mv = mv_selectPlotType(2);

return