function coords = getCurROIcoords(view)
%
% coords = getCurROIcoords(view)
% 
% Gets ROI.coords from currently selected ROI.  Error dialog if no
% selectedROI.
%
% djh 4/24/98

if view.selectedROI
  coords = view.ROIs(view.selectedROI).coords;
else
  myErrorDlg('No ROI selected');
end

