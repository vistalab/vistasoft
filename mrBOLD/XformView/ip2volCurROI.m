function volume = ip2volCurROI(inplane,volume)
%
% volume = ip2volCurROI(inplane,volume)
%
% Calls ip2volROI with the currently selected ROI.  Called from
% callback in xformVolumeMenu.
%
% djh, 8/98
%
% Modifications:
% djh, 2/2001, replaced globals with local variables

if ~inplane.selectedROI
  myErrorDlg('Must have a selected ROI in the Inplane window before it can be transformed to the Volume window.');
end

ipROI = inplane.ROIs(inplane.selectedROI);
volROI = ip2volROI(ipROI,inplane,volume);
volume = addROI(volume,volROI,1);
if ~isequal(volume.name, 'hidden')
    volume = selectCurROISlice(volume);
end
volume = refreshScreen(volume);

return
