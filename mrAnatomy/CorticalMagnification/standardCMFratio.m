function ratio = standardCMFratio(dscale)
% 
% PURPOSE:
%   Given the cortmag function fit parameter 'dscale', we
%   compute the ratio of the cortical distance from 2-4 deg to
%   the distance from 10 to 12 deg. 
%
%   The standard shape of the CMF is
%   
%       predictedDegVisAngle = exp(dScale*dist + ln(10))
%
%   Thus, the distance given the predictedDegVisAngle is:
%
%       dist = (ln(predictedDegVisAngle) - ln(10))/dscale
%
%   And, the ratio is:
%   
%       (dist(2 deg) - dist(4 deg))/(dist(12 deg) - dist(10 deg))
%
%   But, since the distance at 10deg is (by definition) 0, we can simplify.
%
%
% HISTORY:
%   2001.11.27 RFD (bob@white.stanford.edu) wrote it.

dist2 = (log(2) - log(10))/dscale;
dist4 = (log(4) - log(10))/dscale;
dist10 = 0;
dist12 = (log(12) - log(10))/dscale;
ratio = (dist4-dist2)/(dist12-dist10);

disp([dist2 dist4 dist10 dist12]);

return;