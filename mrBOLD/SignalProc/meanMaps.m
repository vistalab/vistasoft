function mnmaps = meanMaps(view)
%
% mnmaps = meanMaps(view)
% 
% Calculates mean map values 
% for all scans, for pixels that are in the currently selected
% ROI.
%
% rmk, 1/20/99

nscans = numScans(view);

% Get selpts from current ROI
ROIcoords = getCurROIcoords(view);

% Compute vector mean for each scan
mnmaps = zeros(1,nscans);
for scanNum = 1:nscans
  mm = meanMap(view,scanNum,ROIcoords);
  mnmaps(scanNum) = mm;
end

