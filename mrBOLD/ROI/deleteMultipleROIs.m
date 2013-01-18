function view = deleteMultipleROIs(view)
%
% view = deleteROI(view,n)
%
% Select multiple ROIs from view.ROIs for deletion
% Actual deletion is done by deleteROI.

%
% djh, 1/26/98
% gmb, 4/25/98 added ROI popup menu code
% fwc, 12/7/02 adapted to deleteMultipleROIs
% fwc  24/7/02  fixed bug


% Select ROIs to delete
nROIs=size(view.ROIs,2);
if nROIs==0
  myErrorDlg('No ROIs to delete')
  return
end
roiList=cell(1,nROIs);
for r=1:nROIs
    roiList{r}=view.ROIs(r).name;
end

%roiList

selectedROIs = find(buttondlg('ROIs to delete',roiList));
%selectedROIs
nROIs=length(selectedROIs);
if (nROIs==0)
    error('No ROIs selected');
end

% delete selected ROIs by name, as their numbers may change
for r=1:nROIs
    s=selectedROIs(r);
    n=findROI(view,roiList{s});
    %fprintf( 'Deleting ROI: %d, %s (list: %d, %s)\n', n, view.ROIs(n).name, s, roiList{s} );
    view=deleteROI(view, n);
end
    
if length(view.ROIs)>0
   view = selectROI(view,1);
end

% Set the ROI popup menu
setROIPopup(view);
