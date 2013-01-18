function view = clearROIall(view)
%
% view = clearROIall(view)
%
% Zeros out selpts in current selected ROI.
%
% djh, 5/26/98

% error if no current ROI
if view.selectedROI == 0
  myErrorDlg('No current ROI');
end

% Save prevSelpts for undo
view.prevCoords = getCurROIcoords(view);

% Clear all the coords
selectedROI = view.selectedROI;
view.ROIs(selectedROI).coords  = [];


