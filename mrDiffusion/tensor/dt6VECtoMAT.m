function M = dt6VECtoMAT(t)
% Converts vector format of the dt6 tensor to a symmetric 3x3 matrix
%
%  M = dt6VECtoMAT(t)
%
% t is a 6-vector containing the entries of the symmetric quadratic
% positive-definite matrix.
%
% The t value order is: q11, q22, q33, q12 q13 q23
%
% Example:
%   t = 1:6
%   dt6VECtoMAT(t)
%
% (c) Stanford Vista team 2011

M(1,1) = t(1);  M(1,2) = t(4); M(1,3) = t(5);
M(2,1) = t(4);  M(2,2) = t(2); M(2,3) = t(6);
M(3,1) = t(5);  M(3,2) = t(6); M(3,3) = t(3);

return
