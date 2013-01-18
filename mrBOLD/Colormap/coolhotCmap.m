function cmap = coolhotCmap(numGrays,numColors, k)
% cmap = coolhotCmap([numGrays],[numColors], [k])
% 
% Makes colormap array with:
%   gray scale - 1:numGrays
%   hot colors - numGrays+1:numGrays+numColors
%   k: gray level for midpoint of colormap [0 1]
% sod 2007/01
%
% jw 5.26.2010: added input arg k, allowing user to make midpoint of
% bicolor map a gray level other than black. this can be useful because
% black is more similar to blue (cool colors) than to red (hot colors)

if ~exist('numGrays','var')
  numGrays=128;
end
if ~exist('numColors','var')
  numColors=96;
end
if ~exist('k','var')
  k = 0;% 0.5; 
end

cmap = zeros(numGrays+numColors,3);
a = gray(numGrays);
b = grayhot(floor(numColors/2), k);
b = flipud(b(:,[3 2 1]));
c = grayhot(ceil(numColors/2), k);
cmap(1:numGrays+numColors,:) = [a;b;c];
