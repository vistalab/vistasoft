function [x,y] = ellipsePoints(a,b,theta,radSpacing,closeEllipse)
% Make samples on an ellipse
%
%  [x,y] = ellipsePoints(a,b,theta,radSpacing,closeEllipse)
%
% Inputs:
%  (a,b): Major and minor axes, x-scale, y-scale
%  theta:  Angle in radians, clockwise
%
% Example
%{
    a = 1; b = 2; theta = pi/3; radSpacing = 0.1; closeEllipse = true;
    [x,y] = ellipsePoints(a,b,theta,radSpacing,closeEllipse);
    mrvNewGraphWin; plot(x,y,'-'); axis square; grid on
%}
% (c) Stanford VISTA  Team

if notDefined('a'), a = 1; end
if notDefined('b'), b = 1; end
if notDefined('theta'), theta = 0; end
if notDefined('closeEllipse'), closeEllipse = false; end

[x,y] = circlePoints(radSpacing);
x = a*x; y = b*y;
% figure(1); plot(x,y); axis equal
rotMat = [cos(theta) -sin(theta); -sin(theta) -cos(theta)];

tmp = [x(:),y(:)]';
tmp = rotMat*tmp;

x = tmp(1,:);
y = tmp(2,:);
% figure(1), plot(x,y); axis equal
                
% If the user asks to close it up, then do it.
if closeEllipse
    x = [x,x(1)]; y = [y, y(1)];
end

end

