function cmap = cool_springCmap(numGrays,numColors)
%COOL   Shades of cyan and magenta color map
%   COOL(M) returns an M-by-3 matrix containing a "cool" colormap.
%   COOL, by itself, is the same length as the current figure's
%   colormap. If no figure exists, MATLAB creates one.
%
%   For example, to reset the colormap of the current figure:
%
%             colormap(cool)
%
%   See also HSV, GRAY, HOT, BONE, COPPER, PINK, FLAG, 
%   COLORMAP, RGBPLOT.

%   C. Moler, 8-19-92.
%   Copyright 1984-2004 The MathWorks, Inc.
%   $Revision: 1.1 $  $Date: 2008/04/30 21:23:29 $

if ~exist('numGrays','var')
  numGrays=128;
end
if ~exist('numColors','var')
  numColors=96;
end

t = 0.6:0.4/(numColors-1):1;
cmap = zeros(numGrays+numColors,3);
cmap(1:numGrays+numColors,:) = [gray(numGrays); diag(t)*[cool(round(numColors/2)).^1.5; spring(round(numColors/2)).^1.5]];
