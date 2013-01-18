function [mn,sd,rng,thresh] = mrspMeanPhase(vw,roiN,wedgeScan,thresh)
%
%   [mn,sd,rng,thresh] = mrspMeanPhase(vw,roiN,wedgeScan,thresh)
%
%Author: Wandell
%Purpose:
%   Determine the mean phase in a scan as a function of coherence level.
%   This is useful for determining the mean phase in a wedge scan, which is
%   ordinarily close to the horizontal meridian.  This value is then used
%   to adjust the color map, for example.
%
%   Very similar information is provided in the mrROIStats function.  This
%   function differs mainly by sweeping out the mean phase as a function of
%   coherence level.
%
% Example:
% [mn,sd,rng,thresh] = mrspMeanPhase(vw,[],wedgeScan,thresh)
% 

% Programming Notes:
%   We should change this routine to perform the calculation in just an
%   ROI, not the whole data set.

if ieNotDefined('vw'), error('View must be defined'); end
if ieNotDefined('roiN'), roiN = []; end
if ieNotDefined('wedgeScan'), wedgeScan = viewGet(vw,'curscan'); end
if ieNotDefined('thresh'), thresh = [0.1:.1:.8]; end

if isempty(roiN)
    co = viewGet(vw,'scancoherence',wedgeScan);
    ph = viewGet(vw,'scanphase',wedgeScan);
else
    % Should just get from the N'th ROI.
end

for ii=1:length(thresh)
    l = (co > thresh(ii));
    [mn(ii),sd(ii),rng(ii)] = meanPhase(ph(l));
end
selectGraphWin;
% Window header
headerStr = ['Mean phase vs. coherence'];
set(gcf,'Name',headerStr);

% Plot it
fontSize = 14;
symbolSize = 4;
plot(thresh,mn,'MarkerSize',symbolSize); grid on;
ylabel('Mean Phase (rad)','FontSize',fontSize);
xlabel('Coherence','FontSize',fontSize);

return
