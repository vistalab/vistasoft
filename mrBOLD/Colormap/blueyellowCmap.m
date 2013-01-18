function cmap = blueyellowCmap(numGrays,numColors)
%
% cmap = blueyellowCmap(numGrays,numColors)
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
cmap(1:numGrays+numColors,:) = [gray(numGrays);blueyellow(numColors)];
return;

function out=blueyellow(nc);
nc  = nc-1;
out = [[0:nc]' [0:nc]' [nc:-1:0]']./nc;
return;
