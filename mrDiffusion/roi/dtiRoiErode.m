function roi = dtiRoiErode(roi, cropAxes)
%
% roi = dtiRoiErode(roi, [cropAxes=[1 1 1]])
%
% Erodes the roi by n points along any of the three axes. E.g., 
% cropAxes = [0 1 1] will erode by 1 point along Y and Z, 
% cropAxes = [3 2 2] will erode by 3 points along X, and 2 points 
% along Y and Z.
%
% HISTORY:
% 2009.08.19 RFD wrote it.

if(~exist('cropAxes','var')||isempty(cropAxes))
    cropAxes = [1 1 1];
end
cropAxes = cropAxes(:)';
if(numel(cropAxes)~=3), error('numel(cropAxes) ~= 3!'); end

cropAxes(cropAxes>0) = cropAxes(cropAxes>0)+1;
stEl = ones(cropAxes+1);

if(isstruct(roi))
    for(ii=1:numel(roi))
        [roiImg, imgXform, bb] = dtiRoiToImg(roi(ii));
        roiImg = imerode(roiImg, stEl);
        roi(ii).coords = dtiRoiCoordsFromImg(roiImg, imgXform, bb);
    end
else
    [roiImg, imgXform, bb] = dtiRoiToImg(roi);
    roiImg = imerode(roiImg, stEl);
    roi = dtiRoiCoordsFromImg(roiImg, imgXform, bb);
end

return;


