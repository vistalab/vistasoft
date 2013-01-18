function roiSaveAllHdf5(view)
% saveAllROIsHdf5(view)
%
% Saves ROI to a file.
%
% davclark@white 03/17/06

if view.selectedROI==0
  myErrorDlg('No ROIs to save')
end

for r=1:length(view.ROIs)
  roiSaveHdf5(view,view.ROIs(r))
end
