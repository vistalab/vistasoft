function [x,y] = ellipsePoints(a,b,theta,radSpacing)
%Make samples on an ellipse
%
%  [x,y] = ellipsePoints(a,b,theta,radSpacing)
%
% (a,b) are x-scale, y-scale
% theta is in radians, clockwise
%
% Example
%    radSpacing = 0.01;
%    a = 1; b = 3; theta = pi/4;
%    [x,y] = ellipsePoints(a,b,theta,radSpacing);
%    x = [x,x(1)]; y = [y, y(1)];   % Close it up for plotting
%    plot(x,y,'-'); axis equal
%
% (c) Stanford VISTA  Team

if notDefined('a'), a = 1; end
if notDefined('b'), b = 1; end
if notDefined('theta'), theta = 0; end

[x,y] = circlePoints(radSpacing);
x = a*x; y = b*y;
% figure(1); plot(x,y); axis equal
rotMat = [cos(theta) -sin(theta); -sin(theta) -cos(theta)];

tmp = [x(:),y(:)]';
tmp = rotMat*tmp;

x = tmp(1,:);
y = tmp(2,:);
% figure(1), plot(x,y); axis equal
                
return;

