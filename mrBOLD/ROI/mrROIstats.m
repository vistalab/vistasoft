function [meanCo, meanPh, meanAmp] = mrROIstats(view,whichROI)
%
%   [meanCo, meanPh, meanAmp] = mrROIstats(view,whichROI)
%
%Author: Wandell
%Purpose:
%   Measure summary statistics within an ROI.  A window appears in the
%   upper right of the screen with the summary statistics.  This same
%   window (based on mrMessage) is reused whenever the routine is called.
%   Perhaps we should bring up multiple windows to allow us to compare.
%
% Example:
%
%  mrROIstats(FLAT{1},7);
%
%
% Programming Note
%   The amp is computed in slightly different ways in mrROIstats and these
%   plotting routines (usually by only a very small amount).
%   These amp values are computed in mrInitRet and the ones in the
%   plotMeanFFTSeries are computed on the fly from the time series.  These
%   can differ because one is 
%   mean(amp) = mean(abs(fft(tseries))) (mrROIStats)
%               abs(fft(mean(tseries))) (plotMeanFFTSeries)
%   This is a potential problem.  When writing up results, make sure that
%   you specify the formula you used properly.


if ieNotDefined('whichROI'), whichROI = view.selectedROI; end

ROIcoords = view.ROIs(whichROI).coords;  
curScan = getCurScan(view);

% Get rerlevant data.
co = getCurDataROI(view,'co',curScan,ROIcoords);
ph = getCurDataROI(view,'ph',curScan,ROIcoords);
amp = getCurDataROI(view,'amp',curScan,ROIcoords);
nPoints = length(co);

meanCo =  mean(co); stdCo = std(co);  seCo = stdCo*sqrt(1/(nPoints - 1)); 
rngCo = max(co(:)) - min(co(:));

[meanPh,stdPh,rngPh] = meanPhase(ph); sePh = stdPh*sqrt(1/(nPoints - 1));

meanAmp =  mean(amp); stdAmp = std(amp); seAmp = stdAmp*sqrt(1/(nPoints - 1));
rngAmp = max(amp(:)) - min(amp(:));

txt = sprintf('ROI # %.0f (%.0f points):\n',whichROI,nPoints);
newText = sprintf('Field\tMean\tStd\tSEM\tRange\n\n'); 

txt = addText(txt, newText);
newText = sprintf('Co:\t%.02f \t(%.02f)\t(%.02f)\t(%.02f)\n',meanCo,stdCo,seCo,rngCo);  
txt = addText(txt, newText);
newText = sprintf('Phase:\t %.02f \t(%.02f)\t(%0.2f)\n',meanPh,stdPh,sePh);  
txt = addText(txt, newText);
newText = sprintf('Amp:\t %.02f   \t(%.02f)\t(%0.2f)\t(%.02f)\n',meanAmp,stdAmp,seAmp,rngAmp);  
txt = addText(txt, newText);

msgHdl = mrMessage(txt, 'left', [0.8 0.8 0.18 0.1], 10);
figure(msgHdl);

return;