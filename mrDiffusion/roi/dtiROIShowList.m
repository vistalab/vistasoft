function showTheseRois = dtiROIShowList(handles)
%
%   showTheseRois = dtiROIShowList(handles);
%
%Author: Dougherty, Wandell
%Purpose
%   Based on the figure settings, including the number of ROIs and the
%   ShowMode build a vector of the ROIs that should be displayed.  Used in
%   various drawing and plotting routines. 
%

if (handles.roiShowMode == 1) ...
        || isempty(handles.rois) ...
        || ((length(handles.rois) == 1) && strcmp(handles.rois.name,'Empty'))
    showTheseRois = [];
elseif (handles.roiShowMode == 2),  showTheseRois = handles.curRoi;
elseif (handles.roiShowMode == 3),  showTheseRois = (1:length(handles.rois));   
elseif (handles.roiShowMode == 4),  showTheseRois = (1:length(handles.rois));
else error('Bad handles.roiShowMode');
end

return;