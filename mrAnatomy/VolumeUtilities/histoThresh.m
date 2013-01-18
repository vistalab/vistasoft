function [M minval maxval] = histoThresh(M);
%  
% [M minval maxval] = histoThresh(M);
%
% Rescale an arbitary matrix M by chopping
% off the tails of the histogram of intensity.
% This is the criterion used to put up functional
% movies in tSeriesMovie. 
%
% Note that M is always returned as a double 
% matrix (need to do math on it, can't w/ int16 or
% uint8 or other numeric matrices).
%
% ras 03/05
% ras 10/07: returns min and max values
if ~isequal(class(M),'double')
    M = double(M);
end

histThresh = prod(size(M))/1000; % ignore bins w/ fewer voxels than this
[binCnt binCenters] = hist(M(:),100);
minval = binCenters(min(find(binCnt>histThresh)));
maxval = binCenters(max(find(binCnt>histThresh)));
M = rescale2(M,[minval maxval],[0 255]);

return