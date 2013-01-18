function newROI = dtiMergeROIs(roi1,roi2)
%
%   newROI = dtiMergeROIs(roi1,roi2)
%
% Author: RFD, BW
% Purpose:
%  Merge ROIs
%
%Example:
% handles = guidata(gcf); roi1 = handles.rois(1); roi2 = handles.rois(2);
% newROI = dtiMergeROIs(roi1,roi2);
% handles = dtiAddROI(newROI,handles,1);
% guidata(gcf,handles);
% dtiRefresh ... or something


newROI = roi1;
newROI.name = sprintf('%s_%s',roi1.name,roi2.name);

newROI.coords = unique(vertcat(roi1.coords,roi2.coords),'rows');

return;