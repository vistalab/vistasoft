function boundedIndices=boundsCheck3D(minCoords,maxCoords,inputCoords)
% function boundedIndices=boundsCheck(minCoords,maxCoords,inputCoords)
% PURPOSE:  returns the indices of those points in inputCoords
% That lie within the bounding box specified by the min and max coordinates
% Works with 3D coordinates.
% AUTHOR : Wade
% DATE : 020801
% Last: $Date: 2007/07/05 19:51:58 $
% Do some size checks
[nInputCoords,nInpDims]=size(inputCoords);
if (nInpDims~=3)
    error('In boundsCheck3D, inputCoords must be n*3');
end
if ((prod(size(minCoords))~=3) | (prod(size(maxCoords))~=3))
 error ('In boundsCheck3D, min and max coords must be 3*1 vectors');
end
% do bounds check
okPoints=(inputCoords(:,1)>minCoords(1)).*(inputCoords(:,2)>minCoords(2)).*(inputCoords(:,3)>minCoords(3));
okPoints=okPoints.*(inputCoords(:,1)<maxCoords(1)).*(inputCoords(:,2)<maxCoords(2)).*(inputCoords(:,3)<maxCoords(3));
boundedIndices=find(okPoints);
