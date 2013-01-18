function cMap = Make3dColormap(name, nColors)
%
% cMap = Make3dColormap(name[, nColors]);
%
% Create a standard set of colormaps for 3D rendering. Name determines
% which standard map to use. Only the first 3 letters are significant.
% Maps include 'red' (red-green), 'hot', 'cool', 'jet', and 'hsv'. All
% other inputs give back the 'prism' color table. The nColors input is
% defaults to 100.
%
% Ress, 6/03

if ~exist('nColors', 'var'), nColors = 100; end

switch name(1:3)
  case 'red'
    red = (0:(nColors-1)) / (nColors-1);
    green = red(nColors:-1:1);
    blue = red * 0;
    cMap = [red; green; blue]';
  case 'hot'
    cMap = hot(nColors);
  case 'coo'
    cMap = cool(nColors);
  case 'jet'
    cMap = jet(nColors);
  case 'hsv'
    cMap = hsv(nColors);
  otherwise
    cMap = prism(nColors);
end

cMap = round(cMap * 255)';
