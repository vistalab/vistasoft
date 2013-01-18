function volume = flat2volCurROI(flat,volume)
%
% volume = flat2volCurROI(flat,volume)
%
% Calls flat2volROI with the currently selected ROI.  Called from
% callback in xformFlatMenu.
%
% djh, 8/98
% 
% Modifications:
% djh, 2/2001, replaced globals with local variables

if ~flat.selectedROI
  myErrorDlg('Must have a selected ROI in the Flat window before it can be transformed to the Volume window.');
end

flatROI = flat.ROIs(flat.selectedROI);
volROI = flat2volROI(flatROI,flat,volume);
volume = addROI(volume,volROI,1);
