function [meanCoherehce,meanAmps,stdCos,semCos] = meanCos(view)
%
% [meanCos,meanAmps] = vectorMeans(view)
% 
% Calculates mean correlations and amplitudes (ignoring phase)
% for all scans, for pixels that are in the currently selected
% ROI.
%
% djh 7/98

nscans = numScans(view);

% Get selpts from current ROI
ROIcoords = getCurROIcoords(view);

% Compute vector mean for each scan
meanCoherehce = zeros(1,nscans);
meanAmps = zeros(1,nscans);
stdCos=zeros(1,nscans);

for scanNum = 1:nscans
  [meanCoVM,meanAmp,stdCo,semCo] = meanCo(view,scanNum,ROIcoords);
  meanCoherehce(scanNum) = meanCoVM;
  meanAmps(scanNum) = meanAmp;
  stdCos(scanNum) = stdCo;
  semCos(scanNum) = semCo;
  
end

