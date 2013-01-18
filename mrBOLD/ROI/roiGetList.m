function [selectedROIs nROIs] = roiGetList(vw, ROIlist)
% [selectedROIs nROIs] = roiGetList(vw, ROIlist)
%
% Aug, 2009: JW 
%
% This code was duplicated many functions. Now it is here.

if notDefined('ROIlist')
    roiList = viewGet(vw, 'roiNames');
    if isempty(roiList), error('[%s]: No available ROIs', mfilename); end
    selectedROIs = find(buttondlg('ROIs to Plot',roiList));
else
    selectedROIs=ROIlist;
end

nROIs=length(selectedROIs);
if (nROIs==0)
    error('No ROIs selected');
end
