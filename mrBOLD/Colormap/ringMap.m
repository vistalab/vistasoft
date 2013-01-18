function [img, mp] = ringMap(mp, diameter, screen, hemisphere, offsetPh)
%
%   [img, mp] = ringMap([mp], [diameter], [screen], [hemisphere], [offsetPh])
%
%AUTHOR:  Baseler (from Engel's expandMap.m and wedgeMap.m)
%DATE:    08.22.96
%PURPOSE:
%  Make one of those darn circular color maps to 
% represent the eccentricity
%
% We are not sure about the scaling logic at the bottom.  What is
% it doing there?  The code needs comments and to be explained.
%
%ARGUMENTS:
% 
% mp:  An eccentricity color map, the last value should
%      be the background color
%            (Default = [ hsv(64) ; .5 .5 .5])
% diameter:  The size of the returned image.
%            (Default = 128)
% screen:  Which screen was used to display the stimulus in
%	   the scanner?  (1 = near, small screen; 2 = far, 
%	   large screen)
%	   (Default = 1)
% hemisphere:  How many hemispheres/hemifields?  (1 or 2)?
%	     (Default = 2)
% offsetPh: How much to offset colormap, in degrees (Default=0)
% 
%RETURNS:
%
% img:  The resulting image
%  mp:  The colormap of the image
%    To display the result use image(img),colormap(mp)
if nargin < 5,  offsetPh = 0;               end
if nargin < 4,  hemisphere = 2;             end
if nargin < 3,  screen = 1;                 end
if nargin < 2,  diameter = 128;             end
if nargin < 1,  mp = [hsv(64); .5 .5 .5];   end

nX = diameter;
nY = diameter(1);
radius = floor(diameter/2);
nMap = size(mp,1);

% Create a grid of (X,Y) values
[X Y] = meshgrid(1:nX,1:nY);

% Center the grid around (0,0)
X = X - (nX/2); Y = Y - (nY/2);

%  Find the radial distance for each of the X,Y points
radii = sqrt(X.^2 + Y.^2);

% Pick out those locations that are within the radius 
% and hemifield(s) desired
if hemisphere == 1
  in = (radii < radius & X >= 0 ); 
else
  in = (radii < radius);
end

%  Convert radial distances to degrees visual angle
if isempty(screen) 
  pixradius = 60;
  screendist = (21.5/.0825);
elseif screen == 2
  pixradius = 228;
  screendist = (127.5/.0664);
elseif screen == 1
  pixradius = 60;
  screendist = (21.5/.0825);
else
  error('Improper screen parameter');
end

pixradii = mrScale(radii,0,radius);
degs = (180/pi)*atan(pixradii ./ screendist);

degs(in) = mrScale(degs(in), 1, (nMap-1));
degs(~in) = nMap*ones(size(degs(~in)));
img = degs;

% Rotate colormap if necessary
if offsetPh
   if offsetPh<0 | offsetPh>360
      error('offsetPh must be between 0 and 360 degrees');
   end
   cutoff = round((nMap-1) * offsetPh/360);
   firstHalf = mp(1:cutoff,:);
   secondHalf = mp((cutoff+1):(nMap-1),:);
   mp = [secondHalf; firstHalf; mp(nMap,:)];
end

return;
