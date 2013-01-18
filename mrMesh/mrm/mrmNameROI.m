function roiName = mrmNameROI(pos);
%
%   roiName = mrmNameROI(pos);
%
%Author: Wandell
%Purpose:
%   Generate a standard name for an ROI produced by the mrMesh routines.
%   By separating this routine out, we can assure that there is consistency
%   between the different ROI names for searching.
%
%   pos is the 3D position in the mrMesh window.  
%
% Example:
%   pos =mrmGet(msh,'cursor');
%   roiName = mrmNameROI(pos);
%

if ieNotDefined('pos'), pos = [0,0,0]; end

roiName = sprintf('mrm-%.0f-%.0f-%.0f',pos(1),pos(2),pos(3));

return;