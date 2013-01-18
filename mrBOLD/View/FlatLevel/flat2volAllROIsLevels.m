function [volume,volRoiIndexList] = flat2volAllROIsLevels(flat,volume)
%
% [volume,volRoiIndexList] = flat2volAllROIsLevels(flat,volume)
%
% Calls flat2volROI with all ROIs.  
%
% rmk, 1/15/99
% 
% Modifications:
% djh, 2/2001, replaced globals with local variables
% rfd, 2002.01.22 removed check for a selected ROI and cleaned comments.
%   Also, we now keep track of the new position of the added ROIs, if
%   requested.

volRoiIndexList = zeros(size(flat.ROIs));

for r=1:length(flat.ROIs)
  volROI = flat2volROILevels(flat.ROIs(r),flat,volume);
  [volume, volRoiIndexList(r)] = addROI(volume,volROI,1);
end
