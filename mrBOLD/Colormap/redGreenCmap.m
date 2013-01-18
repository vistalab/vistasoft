function cmap = redGreenCmap(numGrays,numColors)
%
% cmap = redGreenCmap(numGrays,numColors)
% 
% Makes colormap array with:
%   gray scale - 1:numGrays
%   redGreen ramp - numGrays+1:numGrays+numColors
%
% djh 1/98

if ~exist('numGrays','var')
  numGrays=128;
end
if ~exist('numColors','var')
  numColors=96;
end

cmap = zeros(numGrays+numColors,3);
cmap(1:numGrays,:) = gray(numGrays);
for i=numGrays+1:numGrays+numColors
  cmap(i,:) = ...
      [((i-numGrays)/numColors)^.5, (1-(i-numGrays)/numColors)^.5, 0];
end
