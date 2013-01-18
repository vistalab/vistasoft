function cmap = hsvDoubleCmap(numGrays,numColors,symmetric)
%
% cmap = hsvDoubleCmap(numGrays,numColors.symmetric)
% 
% Makes colormap array with:
%   gray scale - 1:numGrays
%   hsv colors - numGrays+1:numGrays+numColors
%
% Double wrapping the colors is useful for visualize retinotopy
% so that 180 deg from one hemifield maps onto a full hsv
% colormap (instead of just half of it).  If symmetric, flip
% second hsv cmap
%
% djh 1/98

if ~exist('numGrays','var')
  numGrays=128;
end
if ~exist('numColors','var')
  numColors=96;
end
if ~exist('symmetric','var')
  symmetric=1;
end

cmap = zeros(numGrays+numColors,3);
if symmetric
  cmap(1:numGrays+numColors,:) = ...
      [gray(numGrays);
      hsv(floor(numColors/2));
      flipud(hsv(ceil(numColors/2)))];
else
  cmap(1:numGrays+numColors,:) = ...
      [gray(numGrays);
      hsv(floor(numColors/2));
      hsv(ceil(numColors/2))];
end
