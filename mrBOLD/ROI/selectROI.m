function view = selectROI(view,n)
%
% view = selectROI(view,n)
%
% Selects the Nth ROI in view.ROIs to be the selected ROI by
% setting the view.selectedROI field.
%
% If isstr(n), then the ROI with the name n is selected.
%
% djh, 1/26/98
% bw,aab  Allowed n to be a string.
% ras, 8/17/04 -- for volume views, auto centers on the selected ROI.
% prevRoi = view.selectedROI; % useful for fast redraws below

if isstr(n)
    roiName = n;
    if ~isempty(view.ROIs)
        nROIs = length(view.ROIs);
        for ii=1:nROIs
            if strmatch(roiName,view.ROIs(ii).name);
                view = selectROI(view,ii);
                return;
            end
		end
		view.selectedROI = 0;
        warning(sprintf('No ROI with name %s.',roiName));
    else
        warning(sprintf('No ROIs in current view.'));
    end

elseif ~isempty(view.ROIs)
    % Select it
    view.selectedROI = n;
    % Reset prevCoords
    view.prevCoords = [];
else
    view.selectedROI = 0;
end

% Update the ROI popup menu and ROI lines, if they exist
% (won't for hidden views)
if checkfields(view, 'ui', 'ROI', 'popupHandle')
    setROIPopup(view);
%     view = refreshScreen(view);
end

return;

