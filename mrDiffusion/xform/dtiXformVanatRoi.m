function handles = dtiXformVanatRoi(handles, mrVistaRoi)
%
% handles = dtiXformVanatRoi(handles, roiCoords)
%
% Uses the xformVAnatToAcpc (see dtiXformVanatCompute) to convert mrVista
% vAnatomy coords to a dtiFiberUI roi.
%
% To convert coords from an ROI file and dt6 file without the GUI:
% roi=load('/biac2/wandell2/data/reading_longitude/fmri/bg040805_MotDisc_noMcNeeded_useAll/Gray/ROIs/LMT.mat');
% dt=load('/biac2/wandell2/data/reading_longitude/dti/bg040719/bg040719_dt6.mat');
% acpcCoords = mrAnatXformCoords(dt.xformVAnatToAcpc, roi.ROI.coords);
%
% SEE ALSO:
% dtiXformVanatCompute, dtiXformRoiToMrVistaVolume
%
% HISTORY:
% 2004.04.30 RFD (bob@white.stanford.edu) wrote it.

if(~isfield(handles, 'xformVAnatToAcpc') | isempty(handles.xformVAnatToAcpc))
    error('xformVAnatToAcpc not computed yet- run "Compute mrVista Xform" from the "Xform" menu.');
end
coords = [mrVistaRoi.coords; ones(1,size(mrVistaRoi.coords,2))];
coords = handles.xformVAnatToAcpc * coords;
coords = coords(1:3,:)';

roi = dtiNewRoi(mrVistaRoi.name, mrVistaRoi.color, coords);
handles = dtiAddROI(roi, handles, 1);

return;
