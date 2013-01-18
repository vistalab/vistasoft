function img = polarAngleColorBar(params, cmap, diameter, background);
% Create an image of a circular colorbar corresponding
% to the polar angle mapped by a visual field-mapping experiment.
%
% img = polarAngleColorBar(params, <cmap>, <diameter>, <background>);
%
% Note that this does the same task as cmapWedge, but does
% it with Rory's retinotopy parameters (basically it's easier
% for him to understand). May merge the two, but for continuity's
% sake this could just be a small side function.
%
% If cmap is omitted, will use the HSV cmap.
%
% diameter: diam. of disc in pixels. <default 256>
% background: [R G B] background color of image <default [.9 .9 .9]>
%
% ras, 01/2006.
if notDefined('cmap'), cmap = hsv; end
if notDefined('diameter'), diameter = 256; end
if notDefined('background'), background = [1 1 1]; end

% setup: we'll append the background color as an extra
% row in the cmap. The index (nColors+1) will make a pixel background.
nColors = size(cmap,1);
cmap(nColors+1,:) = background;

% Create a grid of (X,Y) values
nX = diameter; nY = diameter;
[X Y] = meshgrid(1:nX, 1:nY);

% Center the grid around (0,0)
X = X - (nX/2); Y = Y - (nY/2);

%  Find the angle for each of the X,Y points
theta = zeros(size(X));
theta = atan2(Y, X);

% rotate the angle around so 12-o-clock is 0, going clockwise;
% then rescale from radians to degrees (polar angle units) 
theta = mod(theta + pi/2, 2*pi);
theta = rad2deg(theta);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now perform the reverse operation to that performed by polarAngle:   %
% map from visual degrees -> corAnal phase                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isequal(lower(params.direction), 'clockwise')
    direction = 1; 
else                                               
    direction = -1;
end

phi_0 = params.startAngle + direction*params.width/2;
m = (direction*params.visualField) / (2*pi);
img = (theta - phi_0) ./ m; % reverse of theta = m*phi + phi_0;

% rescale the image units (which are now in radians) to range
% from 1 to the # of colors in the cmap
img = mod(img, 2*pi);
img = normalize(img, 1, nColors);

% mask out any values outside the range mapped by the experiment
% (between the start angle and the start angle + visual field mapped):
if params.visualField < 360
    phi_1 = mod(phi_0 + direction*params.visualField, 360);
    if (phi_1 > phi_0) % mapped region doesn't wrap around 0 degrees
        unmapped = find(theta<phi_0 | theta>phi_1);
    else               % mapped region wraps around 0 degrees
        unmapped = find(theta>phi_1 & theta<phi_0);
    end
    img(unmapped) = nColors+1;
end

% Pick out those locations that are outside the radius or angle.
% and set them to the background color.
% (we add an extra row to the cmap for the background color)
dist = sqrt(X.^2 + Y.^2);
radius = diameter/2;
outRadius = (dist > radius);
img(outRadius) = nColors+1; 

% convert image to truecolor
img = ind2rgb(round(img), cmap);

return

