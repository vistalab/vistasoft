function [err, predictedDeg] = poirsonWandellCortMagErr(parm, cortMag)
%
% [err, predictedDeg] = poirsonWandellCortMagErr(parm, cortMag)
%
% AUTHOR: Wandell
% DATE:  11.17.00
% PURPOSE:
%    Fit both the distance scale factor and the foveal phase 
% to a set of expanding ring data
%
%

dScale = parm(1);
dShift = parm(2);

% We restrict the range on the estimated fovealPhase to be
% a little past CORTMAG.fovealPhase.  This variable has the
% foveal phase of the stimulus.
% If the search parameter is smaller than the stimulus phase, well, that
% can't be right.  We belive in causality.
% If the parameter is more than 4-5 sec of hemodynamic delay,
% we also get unhappy and kick back a large error.
% We don't ask for the time, sigh.  So for now
% we assume the period is 36 sec and we demand that the phase be less than
% 2*pi/9;
% Finally, we need to make these measurements in complex phase representation
% to avoid wrapping problems near 0 and 2pi
%
phaseDifference = angle(exp(sqrt(-1)*(parm(3) - cortMag.fovealPhase)));
radPerSec = (2*pi)/36;
oneSec    = 1*radPerSec;
fiveSec   = 1.1*radPerSec;
if (phaseDifference < oneSec) | (phaseDifference > fiveSec)
    err = 10000000;
    if nargout == 2
        predictedDeg = NaN;
    end
    return;
else
    fovealPhase = parm(3);
end

% Use the basic function of distance to predict the visual
% field representation in degrees given the distance scale
% parameter, dScale.  This form keeps dist = 0 at 10 deg.
dist = cortMag.allCorticalDist - dShift;
predictedDeg = exp(dScale*dist + log(10));
% figure(testFig);
% plot(dist, predictedDeg,'o')

% Convert the predicted degrees into expected stimulus phase
% as a complex number.  This conversion assumes that the foveal
% phase is 0.  
predictedRad = (2*pi)*(predictedDeg/cortMag.stimulusRadius);
predictedCx = exp(sqrt(-1)*predictedRad);
% figure(testFig);
% plot(dist, predictedRad,'o')
% plot(dist, angle(predictedCx),'o')

% Adjust the observed CX phases so that the foveal phase is 0.
% This is assumed by the function when we map from phase
% to degrees, later.  
% WE SHOULD BE ABLE TO SET A RANGE OR EVEN FIX THE fovealPhase
% Figure out how to do this here!
%
observedCx = cortMag.allMeanPh/exp(sqrt(-1)*fovealPhase);

err = norm(predictedCx - observedCx);

if nargout == 2
   predictedRad = angle(predictedCx);
   l = find(predictedRad < 0);
   predictedRad(l) = predictedRad(l) + 2*pi;
   
   % Take into account the fact that we sometimes run the
   % phase map with a restricted range
   %
   phRange = phaseRange(CORTMAG);
   rad2deg = cortMag.stimulusRadius/phRange;
   predictedDeg = rad2deg*predictedRad;
   % figure(testFig);
   % plot(dist, predictedDeg,'o')
end

return;

% DEBUGGING AND NOTES

