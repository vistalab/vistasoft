function y = nanmeanDims(x,dim);
%
% y = nanmeanDims(x,dim);
%
% Take the mean, ignoring NaNs, along a specified
% dimension.
% 
% MATLAB 7 nanmean already does this, but since
% a lot of machines use older versions, I thought
% I'd make this version. My algorithm is probably 
% much less efficient than Mathworks'. :)
%
% ras, 04/05.
if nargin < 2
    help(mfilename);
    return
end

if isempty(x)
    y = [];
    return
end

% first, check that the size is >1 along
% the specified dimension. If it isn't, you
% don't need to do anything (but if it is,
% the nanmean below will be along the wrong 
% dim):
if size(x,dim)==1
    y = x;
    return
end

% older versions of nanmean only work
% along the 1st dimension. So, permute
% to get the desired dim as the first
% dimension:
dims = 1:ndims(x);
newOrder = [dim setdiff(dims,dim)];
y = permute(x,newOrder);

% take the mean ignoring NaNs.
y = nanmean(y);

% permute back to the right dim order
[ignore oldOrder] = sort(newOrder);
y = permute(y,oldOrder);

return
