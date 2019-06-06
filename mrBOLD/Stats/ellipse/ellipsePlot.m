function [x,y] = ellipsePlot(a,b,theta,radSpacing)
% Make samples on an ellipse
%
%  [x,y] = ellipsePlot(a,b,theta,radSpacing,closeEllipse)
%
% Inputs:
%  (a,b): Major and minor axes, x-scale, y-scale
%  theta:  Angle in radians, clockwise
%
% Example
%{
    a = 1; b = 2; theta = pi/3; radSpacing = 0.1;
    [x,y] = ellipsePlot(a,b,theta,radSpacing);
%}
% (c) Stanford VISTA  Team

if notDefined('a'), error('a Parameter required'); end
if notDefined('b'), error('b Parameter required'); end
if notDefined('theta'), theta = 0; end

% Points for a closed ellipse
[x,y] = ellipsePoints(a,b,theta,radSpacing,true);

% Bring up one of the local window methods
if     exist('mrvNewGraphWin','file'), mrvNewGraphWin;
elseif exist('ieNewGraphWin','file'),  ieNewGraphWin;
end

plot(x,y,'-'); axis square; grid on

end