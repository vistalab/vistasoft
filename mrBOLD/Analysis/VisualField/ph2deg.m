function cortMag = ph2deg(cortMag)%% AUTHOR:  BW/AB% Date:    10.15.00% PURPOSE:%   Convert the phase measurements into degrees of visual angle.  This% should be done in a way so that the phase values stay consistent with% the mrLoadRet phase plots in the various windows.  They run from [0,2pi].% This is a bit of a challenge because angle(mnPh) returns us a number that% runs from [-pi,pi].  So, keep an eye out.%%
if cortMag.peripheralPhase == cortMag.fovealPhase   phRange = 2*pi;else
   phRange = angle(exp(sqrt(-1)*(cortMag.peripheralPhase - cortMag.fovealPhase)));   if phRange < 0      phRange = phRange + 2*pi;   endend
degPerRadian = cortMag.stimulusRadius/phRange;

% We have the foveal phase estimate from the fitStandardCMF% function.  To map into degrees, we must use that estimate%fovealPhaseCx = exp(sqrt(-1) * cortMag.fitParms.fovealPhase);
% Here, we set the estimated foveal phase to fall on the x-axis% and we convert the complex phases in allUPh to% radians that match mrLoadRet data and fall between [0,2pi].  %%allUPhRad = complexPh2PositiveRad(cortMag.allMeanPh/fovealPhaseCx);% I think this is better. If the phases at the beginning go a little negative, we want to % keep them there, not wrap them around to 2pi.
allUPhRad = complexPh2PositiveRad(cortMag.allMeanPh) - cortMag.fitParms.fovealPhase;allUPhRad = unwrapPhases(allUPhRad);
cortMag.allStimDeg = degPerRadian*allUPhRad;cortMag.allStimDegSE = degPerRadian*cortMag.allSEPh;
return;
