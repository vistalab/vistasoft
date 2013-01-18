function cmap = purplegreenCmap(numGrays,numColors)
% cmap = purplegreenCmap(numGrays,numColors)
% 
% Makes colormap array with:
%   gray scale - 1:numGrays
%   hot colors - numGrays+1:numGrays+numColors
%
% sod 2009/05

if ~exist('numGrays','var')
  numGrays=128;
end
if ~exist('numColors','var')
  numColors=96;
end

cmap = zeros(numGrays+numColors,3);
a = gray(numGrays);
b = hot(floor(numColors/2));
b = [sum(b(:,[2 3])./2,2)  sum(b(:,[1 2])./2,2) sum(b(:,[1 3])./2,2) ];
b = flipud(b);
c = hot(ceil(numColors/2));
c = [sum(c(:,[1 2])./2,2)  sum(c(:,[2 3])./2,2) sum(c(:,[1 3])./2,2)];
cmap(1:numGrays+numColors,:) = [a;b;c];

return
