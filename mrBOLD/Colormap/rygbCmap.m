function cmap = rygbCmap(numGrays,numColors)
%
% cmap = rygbCmap(numGrays)
% 
% Makes colormap array with:
%   gray scale - 1:numGrays
%   red, yellow, green, blue - next 4 colors
%
% djh 1/98

if ~exist('numGrays','var')
  numGrays=128;
end

nRs=floor(1/4*numColors);
nYs=floor(1/2*numColors)-nRs;
nGs=floor(3/4*numColors)-nRs-nYs;
nBs=numColors-nGs-nYs-nRs;

cmap = zeros(numGrays+numColors,3);
cmap(1:numGrays,:) = gray(numGrays);
cmap(numGrays+1:numGrays+nRs,:) = ones(nRs,1)*[1 0 0];
cmap(numGrays+nRs+1:numGrays+nRs+nYs,:) = ones(nYs,1)*[1 1 0];
cmap(numGrays+nRs+nYs+1:numGrays+nRs+nYs+nGs,:) = ones(nGs,1)*[0 1 0];
cmap(numGrays+nRs+nYs+nGs+1:numGrays+numColors,:) = ones(nBs,1)*[0 0 1];
