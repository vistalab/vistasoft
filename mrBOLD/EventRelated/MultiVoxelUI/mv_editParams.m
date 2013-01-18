function mv = mv_editParams(mv);
%
% mv = mv_editParams(mv);
% 
% Set event-realted params for the scans from which a multi-voxel UI was
% taken, and re-chop the data.
%
% ras 09/2006
if notDefined('mv'), mv = get(gcf, 'UserData'); end
if ishandle(mv), mv = get(mv, 'UserData'); end

hV = eval( sprintf('initHidden%s', mv.roi.viewType) );
hV = selectDataType(hV, mv.params.dataType);
hV = setCurScan(hV, mv.params.scans(1));
params = er_editParams(mv.params, mv.params.dataType, mv.params.scans);
er_setParams(hV, params);

mv.voxData = er_voxDataMatrix(mv.tSeries, mv.trials, mv.params);

if isfield(mv, 'glm')
    mv = mv_applyGlm(mv);
end

% assign back to the UI and refresh
if checkfields(mv, 'ui', 'fig') 
    set(mv.ui.fig, 'UserData', mv);
    multiVoxelUI;
end

return
