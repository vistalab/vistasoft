function inplane = vol2ipAllROIs(volume,inplane)
%
% inplane = vol2ipAllROIs(volume,inplane)
%
% Calls vol2ipROI with all ROIs.
%
% rmk, 1/15/99
% djh, 2/2001, replaced globals with local variables

% if ~volume.selectedROI
%   myErrorDlg('Must have a selected ROI in the Volume window before it can be transformed to the Inplane window.');
% end

for r=1:length(volume.ROIs)
  volROI = volume.ROIs(r);
  ipROI = vol2ipROI(volROI,volume,inplane);
  
    % if no coords exist in the inplanes, offer user the option of not xforming
    % this ROI
    if isempty(ipROI.coords)
        q = 'This ROI lies outside the inplane range. Xform empty ROI?';
        resp = questdlg(q, ipROI.name);
        if isequal(resp, 'No')
            continue
        elseif ~isequal(resp, 'Yes'); % cancel or close dialog
            fprintf('%s: user aborted. \n', mfilename);
            return
        end
    end

    % add but don't select (we'll select the last one at the end)
    inplane = addROI(inplane, ipROI, 0);
end

% select last one (so only 1 redraw at most):
inplane = selectROI(inplane, length(inplane.ROIs));


return

