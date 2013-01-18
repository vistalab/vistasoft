function Y = symNormalRnd(M, S, sz)

% Generates independent symmetric matrices
% according to a matrix-variate symmetric normal distribution.
%
% Y = symNormalRnd(M, S, sz)
%
%
% Input:
%   M       pxp mean symmetric matrix
%   S       qxq covariance matrix
%   sz      size of the array (e.g. number of samples)
%
% Output:
%   Y       pxpx[sz] array of random symmetric matrices.
%
% Copyright: Armin Schwartzman, 2009
%

% HISTORY:
%   2008.12.30 ASH (armins@hsph.harvard.edu) wrote it.

% Check inputs
if (size(M,1) ~= size(M,2)),
    error('Wrong input format');
end
if (size(S,1) ~= size(S,2)),
    error('Wrong input format');
end
p = size(M,1);
q = p*(p+1)/2;
if (size(S,1) ~= q),
    error('Wrong input format');
end
if ~exist('sz'),
    sz = 1;
end

%-----------------------------------------------------------------
% Generate multivariate normal
N = prod(sz);       % number of samples
z = mvnrnd(zeros(1,q), S, N);   % size Nxq
z = reshape(z', [q sz]);        % size qxN
Y = repmat(M, [1 1 sz]) + vecdinv(z);

return
