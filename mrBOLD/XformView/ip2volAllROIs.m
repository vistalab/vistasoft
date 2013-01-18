function volume = ip2volAllROIs(inplane,volume)
%
% volume = ip2volAllROIs(inplane,volume)
%
% Calls ip2volROI with the currently selected ROI.  Called from
% callback in xformVolumeMenu.
%
% rmk, 1/15/99
%
% Modifications:
% djh, 2/2001, replaced globals with local variables

% if ~inplane.selectedROI
%     myErrorDlg('Must have a selected ROI in the Inplane window before it can be transformed to the Volume window.');
% end

for r=1:length(inplane.ROIs)
    ipROI = inplane.ROIs(r);
    volROI = ip2volROI(ipROI,inplane,volume);
    if isempty(volROI), continue; end   % no voxels mapped to volume
    volume = addROI(volume,volROI,1);
end

return
