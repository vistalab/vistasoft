function origin = dtiMrMeshOrigin(handles)
% Computes the (x,y,z) origin of the image plane data
%
%   origin = dtiMrMeshOrigin(handles)
%
% NOTE: This routine was extracted from dtiMrMesh3AxisImage so we could
% build independent mrMesh outputs.  I think it may be computing the origin
% of the quarter images from dtiSplit... routine.
%
% Authors: Wandell, Dougherty
%
% Stanford VISTA Team

curPosition = dtiGet(handles,'curpos');

[xImX,xImY,xImZ] = dtiMrMeshImageCoords(handles,1,curPosition(1));
[yImX,yImY,yImZ] = dtiMrMeshImageCoords(handles,2,curPosition(2));
[zImX,zImY,zImZ] = dtiMrMeshImageCoords(handles,3,curPosition(3));

% For x,y,z you place the current position into the relevant location and
% then for the other two you find the value that is zero (which is the
% mid-point of the coordinates and substract off half of the number
% coordinates. I don't understand why (BW).
origin.x = -[-curPosition(1), ...
        find(xImY(:,1)==0) - length(xImY(:,1))/2, ...
        find(xImZ(1,:)==0) - length(xImZ(1,:))/2];

origin.y = -[find(yImX(:,1)==0) - length(yImX(:,1))/2, ...
        -curPosition(2), ...
        find(yImZ(1,:)==0) - length(yImZ(1,:))/2];

origin.z = -[find(zImX(1,:)==0) - length(zImX(1,:))/2, ...
        find(zImY(:,1)==0) - length(zImY(:,1))/2, ...
        -curPosition(3)];

return;

%------------------------------------
function [x,y,z] = dtiMrMeshImageCoords(handles,sliceThisDim,sliceNum)
%
%   [x,y,z] = dtiMrMeshImageCoords(handles,sliceThisDim,sliceNum);
%
% Produces an array of grid points that can be transformed in dtiGetSlice
% to image coords.  They are used for interpolating values in dtGetSlice.
%
% This routine should be extracted and then called from dtGetSlice  instead
% of the code that is there.
%
% Stanford VISTA Team

imDims = dtiGet(1, 'defaultBoundingBox');

nvals = max(imDims) - min(imDims) + 1;

% Computes a single integer for the desired slice, and two vectors showing
% the support of the other two.  So, if you are in the x-slice, you get
% that number of the x-slide and two vectors showing the y and z
% coordinates.
if(sliceThisDim == 1), x = sliceNum;
else x = linspace(imDims(1,1),imDims(2,1),nvals(1)); 
end;

if(sliceThisDim == 2), y = sliceNum;
else y = linspace(imDims(1,2),imDims(2,2),nvals(2)); 
end;

if(sliceThisDim == 3), z = sliceNum;
else z = linspace(imDims(1,3),imDims(2,3),nvals(3)); 
end;

% Convert the single number and the two linear dimensions into 3 3D
% matrices that define the x,y,z coordinates at each anatomical point.
% The singleton dimension is all one value, and the other two 3D
% matrices combine
[x,y,z] = meshgrid(x,y,z);

% Squeeze out the singleton dimension.
x = squeeze(x);
y = squeeze(y);
z = squeeze(z);

return
