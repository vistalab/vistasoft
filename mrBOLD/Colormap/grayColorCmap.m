function cmap = grayColorCmap(numGrays,numColors)
%
% cmap = grayColorCmap(numGrays,numColors)
% 
% Makes colormap array with:
%   gray scale - 1:numGrays
%   jet colors - numGrays+1:numGrays+numColors
%
% This one differs from grayCmap.m as this one has both gray band and color
% band in gray color.

if ~exist('numGrays','var')
    numGrays = 128;
end
if ~exist('numColors','var')
    numColors = 128;
end

cmap = zeros(numGrays+numColors,3);
cmap(1:numGrays+numColors,:) = [gray(numGrays);gray(numColors)];
