function cmap = cool_hotCmap(numGrays,numColors)
%
% cmap = cool_hotCmap(numGrays,numColors)
% 
% Makes colormap array with:
%   gray scale - 1:numGrays
%   cool colors: - numGrays+1:numGrays+numColors/2
%   hot colors: - numGrays+numColors/2+1:numGrays+numColors
%
% djh 1/98

if ~exist('numGrays','var')
  numGrays=128;
end
if ~exist('numColors','var')
  numColors=128;
end

cmap = zeros(numGrays+numColors,3);
c = cool(numColors); c = c(1:end/2,:);
h = hot(numColors); h = h(end/2+1:end,:);
cmap(1:numGrays+numColors,:) = [gray(numGrays);c;h];
