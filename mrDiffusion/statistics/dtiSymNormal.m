function [X] = dtiSymNormal(M, S, N)

% [X] = dtiSymNormal(M, S, [N])
%
% Generates N independent arrays of positive definite matrices
% according to a symmetric-matrix-variate normal distribution.
%
% Input:
%   M       XxYxZxq (or nxq) dt6 array of positive definite means.
%               (n is the number of voxels; q is usually 6 but
%               it can be any integer q = p(p+1)/2).
%   S       XxYxZxqxq (or nxqxq) array of voxel-wise covariance matrices.
%   N       number of repeats
%
% Output:
%   X       XxYxZxqxN (or nxqxN) dt6 array of random symmetric matrices.
%
% Copyright: Armin Schwartzman, 2005
%

% HISTORY:
%   2005.05.19 ASH (armins@stanford.edu) wrote it.
%   2008.01.23 ASH (armins@hsph.harvard.edu) fixed bugs.

% Inputs
if ndims(M)<4,
    M = shiftdim(M,-2);
    Ind = 1;
else Ind = 0;
end
if ndims(M)>4,
    error('Wrong input format');
end
sz = size(M);
q = sz(4);
p = (-1 + sqrt(1+8*q))/2;
if p ~= round(p),
    error('size of M must be p(p+1)/2 for some integer p')
end

if ndims(S)<5,
    S = shiftdim(S,-2);
end
if ndims(S)>5 | (size(S,4)~=q) | (size(S,5)~=q),
    error('Wrong input format');
end

if ~exist('N'),
    N = 1;
end

%-----------------------------------------------------------------

% Generate multivariate normal
nvox = prod(sz(1:3));       % number of voxels
S = reshape(permute(S, [4 5 1:3]), [q q nvox]);
Y = mvnrnd(zeros(1, q), repmat(S, [1 1 N]));   % size (nvox*N)xq
Y = reshape(Y, [sz(1:3) N q]);                 % size XxYxZxNxq
Y = permute(Y, [1:3 5 4]);                     % size XxYxZxqxN

% Add mean
X = Y + repmat(M, [1 1 1 1 N]);

if Ind,
    X = shiftdim(X, 2);
    Y = shiftdim(Y, 2);
end

return
