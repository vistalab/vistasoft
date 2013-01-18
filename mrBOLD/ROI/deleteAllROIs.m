function view = deleteAllROIs(view)
%
% view = deleteAllROIs(view)
%
% Deletes the ROIs in view.ROIs.
%
% djh, 1/26/98

view.ROIs = {};
view.selectedROI = 0;

% Set the ROI popup menu
setROIPopup(view);
