function [x,y] = ellipsePlot(center, axesSize, theta, radSpacing)
% Plot an ellipse in a figure
%
% Syntax:
%  [x,y] = ellipsePlot(center, axesSize, theta, radSpacing)
%
% Brief description:
%   Plots an ellipse in the plane.  Note: the theta is in radians and
%   everything else in degrees.  Maybe I should change that
%
% Inputs:
%
%  center:     Center in degrees (default (0,0))
%  axesSize:   Major and minor axes in degrees (default (1,1))
%  theta:      Angle in radians, clockwise (default, 0)
%  radSpacing: Spacing of point samples in radians (default 0.1)
%
% (c) Stanford VISTA  Team
%
% See also
%   ellipsePoints

% Examples:
%{
  ellipsePlot();
%}
%{
  center = [1,1]; axesSize = [1,1.5]; theta = pi/3; radSpacing = 0.1;
  [x,y] = ellipsePlot(center, axesSize, theta, radSpacing);
%}

%% By default, a unit circle
if notDefined('center'),     center = [0,0]; end
if notDefined('theta'),      theta = 0; end
if notDefined('axesSize'),   axesSize = [1,1]; end
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