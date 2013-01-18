function x = vecd(X)

% x = vecd(X)
% 
% Converts the leading dimensions of X from a symmetric matrix
% to a vector.
% The rest of the coordinates are untouched but shifted accordingly.
% The elements of the matrix are taken diagonal first and then
% off-diagonals by rows and columns on the upper triangular part.
% The off-diagonals are multiplied by sqrt(2).
% The number of elements size(x,1) is equal to p*(p+1)/2,
% where the symmetric matrix is p by p.
%
% Example:
% If size(X) = [3 3 N], then size(x) = [6 N]
% where, if each 3x3 matrix has the format
%   [[X1 X4 X5]
%    [*  X2 X6]
%    [*  *  X3]]
% then each 6-vector has the format
%   x = [X1 X2 X3 sqrt(2)*X4 sqrt(2)*X5 sqrt(2)*X6].
%
% Notice that the elements (*) are ignored (so the function works for
% symmetric and antisymmetric matrices, or extracts the upper triangular
% part of any matrix).
% 
% Utilities:
%   ndsym2vec

% HISTORY:
%   2008.12.31 ASH (armins@hsph.harvard.edu) wrote it.
%

sz = size(X);
if (sz(1) ~= sz(2)),
    error('Wrong input format');
end
p = sz(1);
q = p*(p+1)/2;

x = ndsym2vec(X, 1);
x(p+1:q,:) = sqrt(2)*x(p+1:q,:);

return
