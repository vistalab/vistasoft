function roiCoords = dtiRoiCoordsFromImg(roiImg, imgXform, bb)
% 
% roiCoords = dtiRoiCoordsFromImg(roiImg, imgXform, bb)
%
% bb is the bounding box, defined in the xformed spaced.
%
%
% HISTORY:
% 2009.08.19 RFD wrote it.

[roiCoords(:,1), roiCoords(:,2), roiCoords(:,3)] = ind2sub(size(roiImg), find(roiImg));
%roiCoords(:,1) = roiCoords(:,1) + bb(1,1) - 1;
%roiCoords(:,2) = roiCoords(:,2) + bb(1,2) - 1;
%roiCoords(:,3) = roiCoords(:,3) + bb(1,3) - 1;
roiCoords = mrAnatXformCoords(imgXform, roiCoords);

return;

