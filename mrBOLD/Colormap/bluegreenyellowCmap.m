function cmap = bluegreenyellowCmap(numGrays,numColors)
% cmap = bluegreenyellowCmap(numGrays,numColors)
% 
% Makes colormap array with:
%   gray scale - 1:numGrays
%   hot colors - numGrays+1:numGrays+numColors
%
% sod 

if ~exist('numGrays','var')
  numGrays=128;
end
if ~exist('numColors','var')
  numColors=96;
end

cmap = zeros(numGrays+numColors,3);
cmap(1:numGrays+numColors,:) = [gray(numGrays);blueredyellow(numColors)];
return;

function out=blueredyellow(nc);
r = linspace(0,1,nc/2)';
z = zeros(nc/2,1);
o = ones(nc/2,1);

out = [[r;o] [z;r] flipud([z;r])];
out = out(:,[2 1 3]);

return;
