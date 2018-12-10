function [roiImg, imgXform, bb] = dtiRoiToImg(coords, imgXform, bb)
% 
% [roiImg, imgXform, bb] = dtiRoiToImg(roi, [imgXform=eye(4)], [bb])
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
% % perimImg = bwperim(roiImg);
% perimRoi = dtiRoiFromImg(roiImg, imgXform, bb);
%
% HISTORY:
% 2009.08.19 RFD wrote it.

if(isstruct(coords))
    coords = coords.coords;
end

if(~exist('bb','var')||isempty(bb))
    bb = [min(coords)-10; max(coords)+10];
    if(~exist('imgXform','var')||isempty(imgXform))
        imgXform = eye(4);
        imgXform(1:3,4) = bb(1,:)'-1;
    end
end
if(~exist('imgXform','var')||isempty(imgXform))
    imgXform = eye(4);
end

sz = abs(diff(ceil(mrAnatXformCoords(inv(imgXform), bb))))+1;
roiImg = false((sz));

% Remove coords outside the bounding box
badCoords = coords(:,1)<bb(1,1) | coords(:,1)>bb(2,1) ...
          | coords(:,2)<bb(1,2) | coords(:,2)>bb(2,2) ...
          | coords(:,3)<bb(1,3) | coords(:,3)>bb(2,3);
coords = coords(~badCoords,:);

%coords(:,1) = coords(:,1) - bb(1,1) + 1;
%coords(:,2) = coords(:,2) - bb(1,2) + 1;
%coords(:,3) = coords(:,3) - bb(1,3) + 1;
coords = round(mrAnatXformCoords(inv(imgXform), coords));
roiImg(sub2ind(size(roiImg), coords(:,1), coords(:,2), coords(:,3))) = true;

return;


