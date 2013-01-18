function [inplane, isEmpty] = vol2ipCurROI(volume,inplane)
%
% [inplane, isEmpty] = vol2ipCurROI(volume,inplane)
%
% Calls vol2ipROI with the currently selected ROI.  Called from
% callback in xformInplaneMenu.
%
% Also returns isEmpty, a logical flag indicating whether the xformed
% ROI has coordinates within the inplanes or not.
%
% djh, 8/98
% djh, 2/2001, replaced globals with local variables
if ~volume.selectedROI
    myErrorDlg('Must have a selected ROI in the Volume window before it can be transformed to the Inplane window.');
end

volROI = volume.ROIs(volume.selectedROI);
ipROI = vol2ipROI(volROI,volume,inplane);

% if no coords exist in the inplanes, offer user the option of not xforming
% this ROI
if isempty(ipROI.coords)
    isEmpty = true;
    q = 'This ROI lies outside the inplane range. Xform empty ROI?';
    resp = questdlg(q, ipROI.name);
    if ~isequal(resp, 'Yes'); % cancel or close dialog
        fprintf('%s: user aborted. \n', mfilename);
        return
    end
else
    isEmpty = false;
end

inplane = addROI(inplane, ipROI, 1);

return
