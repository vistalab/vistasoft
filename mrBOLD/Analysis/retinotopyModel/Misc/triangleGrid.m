function [x,y]=triangleGrid(bounds,distance)
% triangleGrid - make triangular grid of points.
%
%  [x,y]=triangleGrid(bounds,distance);
%
% Example: 
%  [x,y]=triangleGrid([-3 3],0.1);
%  plot(x,y,'o');axis equal;
% makes and plots a triangular grid between -3 and 3 with a grid point 
% distance of 0.1: 

% 2007/02 SOD: adapted from David Legland's code.

if nargin < 2,
  help(mfilename);
  return;
end;

dx = distance;
dy = distance.*sqrt(3);
center = mean(bounds);

% make two square grids with different centers
% find all x coordinate
x1 = bounds(1) + mod(abs(center-bounds(1)), dx);
x2 = bounds(2) - mod(abs(center-bounds(2)), dx);
% find all y coordinate
y1 = bounds(1) + mod(abs(center-bounds(1)), dy);
y2 = bounds(2) - mod(abs(center-bounds(2)), dy);
[X1, Y1] = meshgrid(x1:dx:x2,y1:dy:y2);

% find all x coordinate
x1 = bounds(1) + mod(abs(center+dx/2-bounds(1)), dx);
x2 = bounds(2) - mod(abs(center+dx/2-bounds(2)), dx);
% find all y coordinate
y1 = bounds(1) + mod(abs(center+dy/2-bounds(1)), dy);
y2 = bounds(2) - mod(abs(center+dy/2-bounds(2)), dy);
[X2, Y2] = meshgrid(x1:dx:x2,y1:dy:y2);

% xy
x = [X1(:); X2(:)];
y = [Y1(:); Y2(:)];

return

