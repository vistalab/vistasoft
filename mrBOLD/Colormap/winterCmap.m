function cmap = winterCmap(numGrays,numColors)
%
% cmap = winterCmap(numGrays,numColors)
% 
% Makes colormap array with:
%   gray scale - 1:numGrays
%   winter colors - numGrays+1:numGrays+numColors
%
% djh 1/98
if ~exist('numGrays','var')
  numGrays=128;
end
if ~exist('numColors','var')
  numColors=96;
end

cmap = zeros(numGrays+numColors,3);
cmap(1:numGrays+numColors,:) = [gray(numGrays); winter(numColors)];

return