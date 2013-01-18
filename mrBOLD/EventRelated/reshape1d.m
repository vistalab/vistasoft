function y = reshape1d(x)
% y = reshape1d(x)
% Reshapes matrix x into 1-D column vector y.
%
% $Id: reshape1d.m,v 1.1 2004/03/12 07:31:58 sayres Exp $


y = reshape(x, [prod(size(x)) 1]);

return;
