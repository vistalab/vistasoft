function coords=inMapWindow(view, scanNum, ROIcoords, mapWindow)
%
% coords = inMapWindow(view, scanNum, ROIcoords, mapWindow)
%
% Returns coords of voxels (for a given scan) that lie within mapWindow
%	
% rmk, 1/12/99, modeled after inPhWindow.m
% djh, 7/13/99, modified to combine restrictMap with restrictCoPh
% dbr, 9/28/99, modified to deal with empty mapWindow
if isempty(mapWindow)
  subROIcoords = ROIcoords;
else
%   if mapWindow(1)>mapWindow(2)
%     myErrorDlg('Invalid mapWindow');
%   end
  
  % Get map for desired scanNum 
  map = getCurDataROI(view, 'map', scanNum, ROIcoords);
  
  % Get ROIcoords for which map is in mapWindow 
  subROIIndices = mapWindowIndices(map, mapWindow);
  coords = ROIcoords(:,subROIIndices);

end

return