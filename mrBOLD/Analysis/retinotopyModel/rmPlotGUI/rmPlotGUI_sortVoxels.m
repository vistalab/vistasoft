function M = rmPlotGUI_sortVoxels(criterion, M);
% Sort voxels in rmPlotGUI.
% 
% M = rmPlotGUI_sortVoxels(criterion, [M=get from cur figure]);
% 
% ras, 09/2008.
if notDefined('M'), M = get(gcf, 'UserData'); end

vals = rmCoordsGet(M.viewType, M.model{M.modelNum}, criterion, M.coords); 

[sortedVals I] = sort(vals);
M.params.roi.coords = M.params.roi.coords(:,I);
M.coords = M.coords(:,I); 
M.tSeries = M.tSeries(:,I); 
set(gcf, 'UserData', M); 
rmPlotGUI('update'); 
  
return