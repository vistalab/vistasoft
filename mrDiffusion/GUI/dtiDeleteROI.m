function handles = dtiDeleteROI(roiNum,handles)
%
%   handles = dtiDeleteROI(roiNum,handles)
%
%Author: Wandell 
%Purpose:
%
% Example:
%    handles = dtiDeleteROI(handles.curRoi,handles)

if ieNotDefined('roiNum'), error('roi number required.'); end
if isempty(handles.rois), warning('No ROIS to delete'); return;  end

nRois = length(handles.rois);
if (roiNum < 1) | (roiNum > nRois), error('Bad roi number.'); end

handles.rois(roiNum) = [];
if (roiNum <= handles.curRoi), handles.curRoi = handles.curRoi - 1; end

if isempty(handles.rois), handles.curRoi = 0; 
elseif handles.curRoi < 1, handles.curRoi = 1; end

return;
