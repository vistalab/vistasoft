function roi = dtiRoiFromImg(roiImg, imgXform, bb)
% 
% roi = dtiRoiFromImg(roiImg, imgXform, bb)
%
% If not the identity matrix, imgXform is typically set to xformToAcpc. This
% has the effect of forcing the roiImg to have the same voxel size as the 
% image that xformToAcpc is based on.
%
% bb is the bounding box, defined in the xformed spaced. Defaults to 
% [min(coords)-10; max(coords)+10].
%
% [roiImg, imgXform, bb] = dtiRoiToImg(roi);
% % Do some processing on the ROI
% perimImg = bwperim(roiImg);
% perimRoi = dtiRoiFromImg(roiImg, imgXform, bb);
%
% HISTORY:
% 2010.03.11 RFD wrote it.

[coords(:,1), coords(:,2), coords(:,3)] = ind2sub(size(roiImg), find(roiImg));
coords(:,1) = coords(:,1) + bb(1,1) - 1;
coords(:,2) = coords(:,2) + bb(1,2) - 1;
coords(:,3) = coords(:,3) + bb(1,3) - 1;
coords = mrAnatXformCoords(inv(imgXform), coords);
roi = dtiNewRoi('roiFromImg','g', coords);

return;


