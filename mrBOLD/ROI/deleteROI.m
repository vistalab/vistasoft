function vw = deleteROI(vw,n)
%
% vw = deleteROI(vw,n)
%
% Deletes the nth ROI in vw.ROIs.  If that happens to be the
% selected ROI, selects the first nonempty ROI in vw.ROIs.
%
% djh, 1/26/98
% gmb, 4/25/98 added ROI popup menu code
% jw,  8/25/11 allow ROI input to be ROI name

if ieNotDefined('n'), n = viewGet(vw,'currentroi'); end

% if n is a string instead of an integer, look up the ROI number
if ischar(n), 
    fullMatch = true;
    n = roiExistName(vw,n,fullMatch);
end

if n==0
  myErrorDlg('No ROIs to delete')
  return;
end

% Here is the deletion
vw.ROIs(n)=[];

% Here is the adjustment
if (vw.selectedROI == n)
    vw.selectedROI = 0;
    if ~isempty(vw.ROIs)
        sel = max(1,n-1);
        vw = selectROI(vw,sel);
    end
elseif (vw.selectedROI > n)
    vw.selectedROI = vw.selectedROI-1;
end

% Set the ROI popup menu
setROIPopup(vw);

return;