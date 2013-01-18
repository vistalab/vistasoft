function mnmap = meanMap(view,scanNum,ROIcoords)
%
% function mnmap = meanMap(view,scanNum,ROIcoords)
% 
% Calculates mean (within ROI) map value for selected scan.
% 
% scanNum: scan number (integer)
% ROIcoords: 3xN array of (y,x,z) coords (e.g., corresponding to
%   the selected ROI).
%
% rmk, 1/20/99
% ras, 07/07: this function seems to conflict with the file 'meanMap'
% that we compute for the mean functional intensity map. Also, it seems
% kind of inappropriately named. We may not want to keep it at all,
% but if we do, maybe we could rename it 'meanMapValueROI', or something
% more accurate? 

% Get co and ph (vectors) for the desired scan, within the
% current ROI.
subMap = getCurDataROI(view,'map',scanNum,ROIcoords);

% Remove NaNs from subCo and subAmp that may be there if ROI
% includes volume voxels where there is no data.
NaNs = find(isnan(subMap));
if ~isempty(NaNs)
  %myWarnDlg('ROI includes voxels that have no data.  These voxels are being ignored.');
  notNaNs = find(~isnan(subMap));
  subMap = subMap(notNaNs);
end

mnmap = mean(subMap);


