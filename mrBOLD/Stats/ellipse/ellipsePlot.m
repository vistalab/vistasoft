function [x,y] = ellipsePlot(theta, center, axesSize, radSpacing)
% Make samples on an ellipse
%
% Syntax:
%  [x,y] = ellipsePlot(theta, center, axesSize, radSpacing)
%
% Brief description:
%   Plots an ellipse in the plane.  Not sure why theta is in radians
%   and everything else in degrees.  Maybe I should change that
%
% Inputs:
%
%  theta:      Angle in radians, clockwise
%  center:     Center in degrees
%  axesSize:   Major and minor axes in degrees
%  radSpacing: Spacing of point samples in radians
%
% Example:
%{
    axesSize = [1,1.5]; center = [1,1]; theta = pi/3; radSpacing = 0.1;
    [x,y] = ellipsePlot(theta,center, axesSize, radSpacing);
%}
% (c) Stanford VISTA  Team

if notDefined('theta'), theta = 0; end
if notDefined('center'), center = [0,0]; end
if notDefined('axesSize'), axesSize = [1,1]; end
if notDefined('radSpacing'), radSpacing = 0.1; end

% Points for a closed ellipse
[x,y] = ellipsePoints(axesSize(1),axesSize(2),theta,radSpacing,true);
x = center(2) + x;
y = center(1) + y;

% Bring up one of the local window methods
if     exist('mrvNewGraphWin','file'), mrvNewGraphWin;
elseif exist('ieNewGraphWin','file'),  ieNewGraphWin;
end

plot(x,y,'-'); axis square; grid on
mx = max(x(:)); my = max(y(:));
set(gca,'xlim',[-1*mx, mx],'ylim',[-1*my,my]);

end