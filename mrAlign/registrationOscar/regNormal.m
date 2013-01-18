function an = regNormal(a,m,M);
% regNormal - re-normalizes the array a to the range [m M]
%
%   an=normal(a,m,M);
%

an=( a-min(a(:)) )*(M-m)/ (max(a(:))-min(a(:))) + m;
