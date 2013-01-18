function flat = vol2flatCurROILevels(volume,flat);
%
% flat = vol2flatCurROILevels(volume,flat)
%
% Calls vol2flatROI with the currently selected ROI.  Called from
% callback in xformFlatMenu.
%
% djh, 8/98
%
% djh, 2/2001, replaced globals with local variables
% ras, 10/2004, version for flat level view

if ~volume.selectedROI
  myErrorDlg('Must have a selected ROI in the Volume window before it can be transformed to the Inplane window.');
end

volROI = volume.ROIs(volume.selectedROI);
flatROI = vol2flatROILevels(volROI,volume,flat);
flat = addROI(flat,flatROI,1);
