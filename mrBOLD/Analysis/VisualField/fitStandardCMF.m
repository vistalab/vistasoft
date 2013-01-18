function cortMag = fitStandardCMF(cortMag,initParms)
% 
% AUTHOR:  Wandell
% DATE:    11.01.00
% PURPOSE:
%   We fit a standard CMF shape to the data. The standard shape is
%   
%       predDeg = exp(dScale*dist + ln(10))
%    
%    This shape is set with distance adjusted so that when dist = 0 pred
%    deg is 10.
%    The shape is fit with two parameters in mind.
%      dScale is a distance scale parameter
%      fovealPhase is a parameter that we adjust
%           so that the mapping from measured phase to deg of visual
%           angle makes sense
%
%    This routine should be made robust to outliers.
%
% Example:
%   dist = [-30:1:20]; dScale = 0.08;
%   predDeg = exp(dScale*dist + log(10));
%   figure(1); plot(dist,predDeg); grid on
%

if ~exist('initParms','var')
   dScale = 0.05;
   dShift = 50;
   radPerSec = (2*pi)/36;
   if isfield(cortMag,'fovealPhase')
      fovealPhase = cortMag.fovealPhase + 1.05*radPerSec;
   else
      fovealPhase = 3*pi/2;
   end
   fprintf('Using initial search parameters %.2f %.2f %.2f for CMF fitting\n',...
      dScale,dShift,fovealPhase);
else
   dScale = initParms(1);
   dShift = initParms(2);
   fovealPhase = initParms(3);
end

% Set up the search
%
initParm = [dScale,dShift,fovealPhase];
options = optimset('fminsearch');
corticalDistance = cortMag.corticalDist;

parm = fminsearch('poirsonWandellCortMagErr',initParm,options,cortMag);

% Adjust the distances so that 0 mm is at 10 deg point
%
cortMag.allCorticalDist10deg = cortMag.allCorticalDist - parm(2);

% Save the fitted parameters
%
cortMag.fitParms.dScale = parm(1);
cortMag.fitParms.dShift = parm(2);
cortMag.fitParms.fovealPhase = parm(3);

return;