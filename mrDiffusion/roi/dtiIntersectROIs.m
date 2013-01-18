function newROI = dtiIntersectROIs(roi1,roi2)
%
%   newROI = dtiIntersectROIs(roi1,roi2)
%
% Author: MBS (modeled on dtiMergeRois)
% Purpose:
%  Intersect ROIs
%
%Example:
% handles = guidata(gcf); roi1 = handles.rois(1); roi2 = handles.rois(2);
% newROI = dtiIntersectROIs(roi1,roi2);
% handles = dtiAddROI(newROI,handles,1);
% guidata(gcf,handles);
% dtiRefresh ... or something


newROI = roi1;
newROI.name = sprintf('%s_AND_%s',roi1.name,roi2.name);

newROI.coords = intersect(roi1.coords,roi2.coords,'rows');

return;