function vw = deleteMultipleROIs(vw)
%
% vw = deleteROI(vw,n)
%
% Select multiple ROIs from vw.ROIs for deletion
% Actual deletion is done by deleteROI.

%
% djh, 1/26/98
% gmb, 4/25/98 added ROI popup menu code
% fwc, 12/7/02 adapted to deleteMultipleROIs
% fwc  24/7/02  fixed bug


% Select ROIs to delete
nROIs=viewGet(vw, 'number of ROIs');
if nROIs==0, warning('No ROIs to delete');return; end

roiList=cell(1,nROIs);
for r=1:nROIs; roiList{r}=vw.ROIs(r).name; end

%roiList
selectedROIs = find(buttondlg('ROIs to delete',roiList));

%selectedROIs
nROIs=length(selectedROIs);
if nROIs==0, warning('No ROIs selected'); return; end

% delete selected ROIs by name, as their numbers may change
for r=1:nROIs
    s=selectedROIs(r);
    n=findROI(vw,roiList{s});
    %fprintf( 'Deleting ROI: %d, %s (list: %d, %s)\n', n, vw.ROIs(n).name, s, roiList{s} );
    vw=deleteROI(vw, n);
end
    
if viewGet(vw, 'number of ROIs') > 0
   vw = selectROI(vw,1);
end

% Set the ROI popup menu
setROIPopup(vw);
