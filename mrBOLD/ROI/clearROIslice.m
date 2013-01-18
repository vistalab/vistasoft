function vw = clearROIslice(vw)
%
% vw = clearROIslice(vw)
%
% Zeros out selpts in current slice of selected ROI.
%
% djh, 1/11/98

% error if no current ROI
if vw.selectedROI == 0
  myErrorDlg('No current ROI');
end

coords = getCurROIcoords(vw);

% Save prevSelpts for undo
vw.prevCoords = coords;

% Get slice orientation
if strcmp('Volume',vw.viewType) | strcmp('Gray',vw.viewType)
  ori = getCurSliceOri(vw);
else
  ori = 3;
end

% Get indices corresponding to current slice
curSlice =viewGet(vw, 'Current Slice');
indices = find(coords(ori,:)~=curSlice);

% set ROI coords according to those indices
selectedROI = vw.selectedROI;
vw.ROIs(selectedROI).coords = coords(:,indices);
