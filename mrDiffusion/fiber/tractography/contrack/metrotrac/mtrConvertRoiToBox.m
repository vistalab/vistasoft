function [center,length] = mtrConvertRoiToBox(coords,xform)
%
% [center,length] = mtrConvertRoiToBox(coords,xform)
%
% HISTORY:
% 2006.10.24 RFD: extracted code from mtrSave.m.
% 2006.11.27 RFD: fixed 0/1 index bug. All ROIs prior to this fix were
% shifted away from the origin by 1 voxel due to the notorious Matlab/C
% indexing difference.

% Convert coordinates to (i,j,k) space
coords = mrAnatXformCoords(inv(xform), coords);
% convert from 1-index to 0-index
for(ii=1:3) coords(:,ii) = coords(:,ii)-1; end
% Get necessary box attributes
% Get X,Y,Z distance
length = max(coords) - min(coords);
center  = max(coords) - length/2;
return;
