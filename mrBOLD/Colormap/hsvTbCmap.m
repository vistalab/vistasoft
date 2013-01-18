function cmap = hsvTbCmap(numGrays,numColors)
%
% cmap = hsvCmap(numGrays,numColors)
% 
% Makes colormap array with:
%   gray scale - 1:numGrays
%   hsv colors - numGrays+1:numGrays+numColors
%
% djh 1/98

if ~exist('numGrays','var')
  numGrays=128;
end
if ~exist('numColors','var')
  numColors=96;
end

cmap = zeros(numGrays+numColors,3);
mymap = hsv(round(numColors.*1.5));
cmap(1:numGrays+numColors,:) = [gray(numGrays);mymap(1:numColors,:)];
