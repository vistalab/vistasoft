function [meanAmps,meanPhs,seAmps,SEM] = vectorMeans(vw, scans)
%
% [meanAmps,meanPhs,seAmps] = vectorMeans(vw, [scans])
% 
% Calculates mean amplitudes and phases for all scans, for pixels
% that are in the currently selected ROI.
%
% djh 4/24/98
% bw  2/19/99 Added seAmps as a temporary measure for returning
% error bars on the plot.
% jw  1/29/10: 'view' => 'vw', added scans as optional input arg

if notDefined('scans'), scans = 1:viewGet(vw, 'nscans'); end
nscans = length(scans);

% Get selpts from current ROI
ROIcoords = getCurROIcoords(vw);

% Compute vector mean for each scan
meanAmps    = zeros(1,nscans);
meanPhs     = zeros(1,nscans);
seAmps      = zeros(1,nscans);
SEM         = zeros(1,nscans);

for s = 1:nscans
  scanNum = scans(s);  
  [meanAmp,meanPh,seZ,meanStd]  = vectorMean(vw,scanNum,ROIcoords);
  meanAmps(s)                   = meanAmp;
  meanPhs(s)                    = meanPh;
  seAmps(s)                     = seZ;
  meanStds(s)                   = meanStd;
  SEM(s)                        = meanStd/numCycles(vw,scanNum);
end

