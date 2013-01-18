function [roiInd coords] = roiGetAllIndices(vw)
% Get the indices of all open ROIs
% [roiInd coords] = roiGetAllCoords(vw)

if notDefined('vw'), vw = getCurView; end

roistodisplay = viewGet(vw, 'ROIs to Display');
ROIs = viewGet(vw, 'ROIs');

for ii = 1:length(roistodisplay)
    thisroi = roistodisplay(ii);
    
    if ii == 1,  coords = ROIs(thisroi).coords;
    else         coords = [coords ROIs(thisroi).coords]; end  
end

% eliminate redundant voxels
if ~exist('coords', 'var') || isempty(coords)
    roiInd = []; coords = []; return;
end
coords = intersectCols(coords, coords);

% coords2index
[roiInd coords] = roiIndices(vw, coords);

return