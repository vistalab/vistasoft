function [meanCo,meanAmp, stdCo,semCo] = meanCo(view,scanNum,ROIcoords)
%
% [meanCo,meanAmp] = meanCo(view,scanNum,ROIcoords)
% 
% Calculates mean (within ROI) correlation and amplitude
% (ignoring phase), for selected scan.
% 
% scanNum: scan number (integer)
% ROIcoords: 3xN array of (y,x,z) coords (e.g., corresponding to
%   the selected ROI).
%
% djh 7/98
% rmk 1/14/99 added fisherz correction for averaging correlations
% aab 12/12/03 added std for co

% Get co and ph (vectors) for the desired scan, within the
% current ROI.
subCo = getCurDataROI(view,'co',scanNum,ROIcoords);
subAmp = getCurDataROI(view,'amp',scanNum,ROIcoords);

% Remove NaNs from subCo and subAmp that may be there if ROI
% includes volume voxels where there is no data.
NaNs = find(isnan(subCo));
if ~isempty(NaNs)
  myWarnDlg('ROI includes voxels that have no data.  These voxels are being ignored.');
  notNaNs = find(~isnan(subCo));
  subCo = subCo(notNaNs);
  subAmp = subAmp(notNaNs);
end

meanCo = fisherzinv(mean(fisherz(subCo)));
stdCo = std(subCo);
semCo=stdCo./sqrt(length(ROIcoords));

meanAmp = mean(subAmp);


