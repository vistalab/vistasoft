function [sd se m] = rstat(data,mask)
% fstat - running statistical measures 
%
% stats = wstat(data,mask);
%
% input: data: data
%        mask: binary mask
%
% output: sd (standard deviation = std(data,1))
%         se (standard error)
%         m (mean)
%
% 2009/02 SD & MV: wrote it.

if ~exist('data','var') || isempty(data), error('Need data'); end
if ~exist('mask','var') || isempty(mask), mask = ones(size(data)); end

% mask data
data = data.*mask;

% number of elements
n = sum(mask);

% mean
m = sum(data)./n;

% standard deviation (devide by n later)
sd = sqrt((sum(data.^2).*n)-(sum(data).^2));

% catch devide by zero
ii = n==0;
sd(ii) = 0;
n(ii) = 1;
sd = sd./n;
se = sd./sqrt(n);

return



