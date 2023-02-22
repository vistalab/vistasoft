function y = nansum(x,dim)
%Replacement for Matlab NANSUM Sum, ignoring NaNs.
%
x(isnan(x)) = 0;
if nargin == 1 % let sum figure out which dimension to work along
    y = sum(x);
else           % work along the explicitly given dimension
    y = sum(x,dim);
end

return;
