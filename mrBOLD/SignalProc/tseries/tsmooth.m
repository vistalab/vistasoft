function filteredM = tsmooth(m,fSize,fSd)
%
% filteredM = tsmooth(m,fSize,fSd)
%
%AUTHOR:  Engel, Wandell
%DATE:    1993-4
%PURPOSE:
%   Take a set of time series values in the columns of m and smooth
% each one by convolution with a Gaussian kernel of support fSize and
% standard deviation of fSd. 
%

kernel = mkGaussKernel([1 fSize],[1 fSd]);
s = size(m);

% 7/09/97 Lea updated to 5.0
filteredM = [];

for i = (1:s(2))
 tmp = evenConv(m(:,i),kernel);
% tmp = mrDeTrend(tmp);
 filteredM = [filteredM;tmp];
end
