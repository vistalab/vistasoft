function [x,y] = circlePoints(radSpacing)
%Make samples on a circle
%
%  [x,y] = circlePoints(radSpacing)
%
% Example
%    radSpacing = 0.11;
%    [x,y] = circlePoints(radSpacing);
%    plot(x,y,'o'); axis equal
%

theta = (0:radSpacing:2*pi);
x = cos(theta); y = sin(theta);

return;

