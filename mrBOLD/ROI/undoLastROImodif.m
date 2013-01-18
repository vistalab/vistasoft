function view = undoLastROImodif(view)
%
% view = undoLastROImodif(view)
%
% 11/97  djh  Wrote it.
% 4/23/98  gmb  Added swap with tmp so user can undo the undo

selectedROI = view.selectedROI;

if ~isempty(view.prevCoords)
  tmp = view.ROIs(selectedROI).coords;
  view.ROIs(selectedROI).coords = view.prevCoords;
  view.prevCoords = tmp;
else
  myErrorDlg('Cannot undo last ROI modification');
end
