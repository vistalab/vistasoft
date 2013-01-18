function [predDeg, dist, cm] = cmStandardFunction(dist,dScale)
% Return standard cortical mag function
%
%   [predDeg, dist, cm] = cmStandardFunction([dist],[dScale])
%
% Standard cortical magnification function as described by Engel et al.,
% 1997. It is defined as
%
%   predEcc = exp(0.063*(dist + 36.54))
%
% which is really the same as
%
%   predEcc = exp(0.063*dist + ln(10))
% 
% The distance is in millimeters, and with this formula when dist = 0, the
% predicted eccentricity is 10 deg.  Individual dScale terms vary, from
% 0.05 to 0.08 or so, in our experience.
%
% We also return the cortical magnification, which is:
%
%    1/derivative(thisFunction)
%
% and has units of mm/deg.  To plot this, remember to use
%
%   plot(dist(2:end),cm)
% 
% because we miss one point in measuring the differential
%
%
% Example:
%   [predDeg,dist] = cmStandardFunction;
%   figure(1), plot(dist,predDeg); grid on
%
%   [predDeg,dist] = cmStandardFunction((-30:0),0.09);
%   figure(1), plot(dist,predDeg); grid on


if ieNotDefined('dist'), dist = (-30:1:20); end
if ieNotDefined('dScale'), dScale = 0.063; end

predDeg = exp(dScale*dist + log(10));

if nargout > 2
    cm = 1 ./ diff(predDeg);
end

return;

