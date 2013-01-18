function [handles, thisRoiNum] = dtiAddROI(roi,handles,setCurrent)
%
%   handles = dtiAddROI(roi,handles,setCurrent);
%
% ROI management
%
% (c) Stanford VISTA Team

if ~exist('roi','var') || isempty(roi), error('fiber group required.'); end
if ~exist('handles','var') || isempty(handles), error('handles required.'); end
if ~exist('setCurrent','var') || isempty(setCurrent), setCurrent = 1; end

nRoi = length(handles.rois);
if isempty(handles.rois), handles = rmfield(handles,'rois'); end

if(~isfield(roi,'mesh'))
    roi.mesh = [];
end

roi.dirty = 1;
thisRoiNum = nRoi + 1;
handles.rois(thisRoiNum) = roi;
if setCurrent, handles.curRoi = thisRoiNum; end

handles = dtiFiberUI('popupCurrentRoi_Refresh',handles);

return;
