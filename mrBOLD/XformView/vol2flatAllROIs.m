function flat = vol2flatAllROIs(volume,flat)
%
% flat = vol2flatAllROIs(volume,flat)
%
% Calls vol2flatROI with the currently selected ROI.  Called from
% callback in xformFlatMenu.
%
% rmk 1/15/99
%
% Modifications:
% djh, 2/2001, replaced globals with local variables

if ~volume.selectedROI
  myErrorDlg('Must have a selected ROI in the Volume window before it can be transformed to the Inplane window.');
end

for r=1:length(volume.ROIs)
  volROI = volume.ROIs(r);
  flatROI = vol2flatROI(volROI,volume,flat);
  flat = addROI(flat,flatROI,1);
end
