function dtiXformRoiToMrVistaVolume(handles, roiNum)
%
% mrVistaFibers = dtiXformRoiToMrVistaVolume(handles, [roiNum])
%
% Uses the xformVAnatToAcpc (see dtiXformVanatCompute) to convert the specified
% ROI to mrVista vAnatomy coords.
%
% HISTORY:
% 2004.05.19 RFD (bob@white.stanford.edu) wrote it.

if(~isfield(handles, 'xformVAnatToAcpc') | isempty(handles.xformVAnatToAcpc))
    error('xformVAnatToAcpc not computed yet- run "Compute mrVista Xform" from the "Xform" menu.');
end
if(~exist('roiNum','var') | isempty(roiNum))
    roiNum = handles.curRoi;
end

view = getSelectedVolume;

for(ii=1:length(roiNum))
    roi = handles.rois(roiNum(ii));
    coords = unique(round(mrAnatXformCoords(inv(handles.xformVAnatToAcpc),roi.coords)),'rows')';
    view = newROI(view, ['dti_' roi.name], 1);
    view.ROIs(view.selectedROI).coords = coords;
end

% Is there a better way to do this?
mrGlobals;
eval([view.name '=view;']);
return;
