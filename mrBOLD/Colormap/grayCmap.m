function cmap = grayCmap(numGrays,numColors)
%
% cmap = grayCmap(numGrays,numColors)
% 
% Makes colormap array with:
%   gray scale - 1:numGrays
%
% djh 1/98

if ~exist('numGrays','var')
  numGrays=128;
end

cmap = zeros(numGrays,3);
cmap(1:numGrays,:) = gray(numGrays);


