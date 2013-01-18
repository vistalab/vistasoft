function coords=inPhWindow(view,scanNum,ROIcoords,phWindow)
%
% coords = inPhWindow(view,scanNum,ROIcoords,phWindow)
%
% Returns coords of voxels for which ph from given scan lies in phWindow
%	
% if phWindow(1)<phWindow(2) returns phWindow(1) <= ph <= phWindow(2)
% if phWindow(1)>phWindow(2) returns ph >= phWindow(1) or ph <= phWindow(2)
% ph and phWindow in radians
%
% djh, 7/98
if isempty(ROIcoords)
	coords = [];
	return
end

% Get ph for desired scanNum (note: there may be NaNs in ph for
% volume voxels that are outside the inplanes, but these voxels
% will be tossed because NaN is not in phWindow).
ph = getCurDataROI(view, 'ph', scanNum, ROIcoords);

% Get ROIcoords for which ph is in phWindow 
subROIIndices = phWindowIndices(ph, phWindow);
coords = ROIcoords(:,subROIIndices);
