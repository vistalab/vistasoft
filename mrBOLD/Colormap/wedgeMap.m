function [img,mp] = wedgeMap(mp,diameter,totAngle)
%  
%  [img,mp] = wedgeMap(mp,diameter,totAngle)
%
%AUTHOR:  Baseler, Wandell
%DATE:    07.23.96
%PURPOSE:
%  Make one of those darn circular color maps to 
% represent the polar angle
%
%ARGUMENTS:
% 
% mp:  A polar angle color map, the last value should
%      be the background color
%            (Default = [ hsv(64) ; .5 .5 .5])
% diameter:  The size of the returned image.
%            (Default 128)
% totAngle:  The angle around the circle the map
%    should sweep out.  [0 is the noon position, and
%    angles run clockwise] 
%            (Default = 180)
%RETURNS:
%
% img:  The resulting image
% mp:   The colormap of the image
%    To display the result use image(img),colormap(mp)
%

% Test parameter
% diameter = 256;
% mp = [hsv(128); 0.5 0.5 0.5];
% totAngle = 360;


if nargin < 3,  totAngle = 180; end
if nargin < 2,  diameter = 128; end
if nargin < 1,   mp = [hsv(64); .5 .5 .5]; end

% Input arguments
%
nX = diameter;
nY = diameter(1);
nMap = size(mp,1);

% Create a grid of (X,Y) values
%
[X Y] = meshgrid(1:nX,1:nY);

% Center the grid around (0,0)
%
X = X - (nX/2); Y = Y - (nY/2);

%  Find the angle for each of the X,Y points
%
ang = zeros(size(X));
posX = (X > 0);
ang(posX) = atan(Y(posX) ./ (X(posX) + eps))*360/(2*pi);
ang = ang + 90;
tmp = rot90(ang + 180,2);
ang(~posX) = tmp(~posX);

dist = sqrt(X.^2 + Y.^2);
radius = diameter/2;

% Pick out those locations that are within a radius 
% and that are on the right side of the axis (i.e., X>0)
%
inRadius = (dist < radius);
inAngle = ( ang < totAngle);

% Scale angles to sweep out the color map except
% for the last entry (which is used for background)
%
ang(inAngle) = mrScale(ang(inAngle),1,(nMap - 1));

% Find positions NOT in the selected range
%
ang(~inRadius) = nMap*ones(size(ang(~inRadius)));
ang(~inAngle) =  nMap*ones(size(ang(~inAngle)));
%imagesc(ang)
img = ang;

% Make an image
%
% figure(1)
% clf
% hold off
% colormap(mp)
% imagesc(img), axis image, axis off
%
% tiffwrite(ang,mp,'rotateMap.tif');
% unix('xv rotateMap.tif &')




