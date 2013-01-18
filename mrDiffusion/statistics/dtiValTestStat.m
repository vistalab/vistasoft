function [T, M, S, DISTR, df] = dtiValTestStat(g1, g2, Y, mask)

% Computes voxel-wise statistics for two groups from a data array of
% diffusion tensors in dt6 format.
%
% The test is H0: both groups have the same eigenvalues, with possibly
% different unknown eigenvectors.
%
%   [T, M, S, DISTR, df] = dtiValTestStat(g1, g2, DT_ARRAY, [MASK])
%
% Input:
%   g1, g2      List of indices that correspond to each group out of 1:N
%                   E.g: g1 = 1:7, g2 = 8:14, N = 14
%   DT_ARRAY    Data array of size XxYxZx6xN (or nx6xN), where X, Y, Z are the volume
%                   dimensions and N is the number of subjects.
%                   (n is the number of voxels).
%   MASK        Optional XxYxZ binary array. Values of T, M and S are computed
%                   where mask = 1; in other voxels, T, M and S are set to 0.
%                   Default is entire volume.
%
% Output:
%   T           XxYxZx1 (or nx1) array of test statistics (0 where mask = 0)
%   M           XxYxZx6x2 (or nx6x2) array of mean tensors (0 where mask = 0)
%   S           XxYxZx1 (or nx1) array of variances (0 where mask = 0)
%   DISTR       'chi2' or 'f'
%   df          degrees of freedom of the appropriate distribution
%
% Utilities:    ndfun.m, dtiSplitTensor.m
%
% WARNING: If using Pentium 4, eliminate NaN's from array before running
% (processor bug).
%
% Copyright by Armin Schwartzman, 2005

% HISTORY:
%   2004.08.29 ASH (armins@stanford.edu) wrote it.
%

% Check inputs
if (ndims(Y)==2 | ndims(Y)==3),
    Ind = 1;    % Data in indexed nx6xN format
    Y = shiftdim(Y, -2);
else
    Ind = 0;    % Data in XxYxZx6xN format
end
if (ndims(Y)<4 | ndims(Y)>5),
    error('Wrong input format');
end
if (~exist('mask')),
    mask = ones([size(Y,1) size(Y,2) size(Y,3)]);
end

% Computations
N1 = length(g1);
N2 = length(g2);
N  = N1 + N2;

q = size(Y, 4);
p = max(roots([1/2 1/2 -q]));
Yavg1 = mean(Y(:,:,:,:,g1),5);
Yavg2 = mean(Y(:,:,:,:,g2),5);
Yavg = mean(Y(:,:,:,:,:),5);
M = cat(5, Yavg1, Yavg2);

[V1,L1] = dtiSplitTensor(Yavg1);
[V2,L2] = dtiSplitTensor(Yavg2);
[V,L] = dtiSplitTensor(Yavg);

% Total variance
d1 = Y(:,:,:,:,g1) - repmat(Yavg1,[1 1 1 1 N1]);
d2 = Y(:,:,:,:,g2) - repmat(Yavg2,[1 1 1 1 N2]);
S = sum(d1(:,:,:,1:p,:).^2, 4) + 2*sum(d1(:,:,:,p+1:q,:).^2, 4) + ...
    sum(d2(:,:,:,1:p,:).^2, 4) + 2*sum(d2(:,:,:,p+1:q,:).^2, 4);
S = sum(S, 5)/(q*(N-2));

% F version
DISTR = 'f';
df = [p, q*(N-2)];
T = N1*N2/N^2 * sum((L1 - L2).^2, 4);
T = df(2)/df(1) * T./(S*(N-2)/N) / q;

% Adjust output
if Ind,
    T = shiftdim(T, 2);
    M = shiftdim(M, 2);
    S = shiftdim(S, 2);
    L = shiftdim(L, 2);
end

return
