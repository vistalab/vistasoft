function flat = vol2flatCurROI(volume,flat)
%
% vol2flatCurROI
%
% Calls vol2flatROI with the currently selected ROI.  Called from
% callback in xformFlatMenu.
%
% djh, 8/98
%
% djh, 2/2001, replaced globals with local variables

if ~volume.selectedROI
  myErrorDlg('Must have a selected ROI in the Volume window before it can be transformed to the Inplane window.');
end

volROI = volume.ROIs(volume.selectedROI);
flatROI = vol2flatROI(volROI,volume,flat);
flat = addROI(flat,flatROI,1);
