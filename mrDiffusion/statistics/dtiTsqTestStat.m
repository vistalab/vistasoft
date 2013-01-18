function [T, M, S] = dtiTsqTestStat(g1, g2, Y, mask)

% Computes voxel-wise Hotelling T^2 statistics for two groups from a data array of
% diffusion tensors in dt6 format.
%
%   [T, M, S] = dtiTsqTestStat(g1, g2, DT_ARRAY, [MASK])
%
% Input:
%   g1, g2      List of indices that correspond to each group out of 1:N
%                   E.g: g1 = 1:7, g2 = 8:14, N = 14
%   DT_ARRAY    Data array of size XxYxZxpxN (or nxpxN), where X, Y, Z are the volume
%                   dimensions and N is the number of subjects.
%                   p is the vector dimension (p = 6 for DT6 data).
%                   (n is the number of voxels).
%   MASK        Optional XxYxZ binary array. Values of M and S are computed
%                   where mask = 1; in other voxels, M and S are set to 0.
%                   Default is entire volume.
%
% Output:
%   T           XxYxZx1 array of test statistics (0 where mask = 0)
%   M           XxYxZxpx2 array of mean vectors for both groups (0 where mask = 0)
%   S           XxYxZxpxp array of covariances (0 where mask = 0)
%
% Utilities:    ndfun.m, dtiSplitTensor.m, dti33to6.m
%
% WARNING: If using Pentium 4, eliminate NaN's from array before running
% (processor bug).
%
% Copyright by Armin Schwartzman, 2005

% HISTORY:
%   2004.06.23 ASH (armins@stanford.edu) wrote it.
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

p = size(Y, 4);
Y = permute(Y, [4 5 1 2 3]); % permutation required by ndfun
Yavg1 = mean(Y(:,g1,:,:,:), 2);
Yavg2 = mean(Y(:,g2,:,:,:), 2);
davg = Yavg1 - Yavg2;
d1 = Y(:,g1,:,:,:)-repmat(Yavg1, [1 N1 1 1 1]);
d2 = Y(:,g2,:,:,:)-repmat(Yavg2, [1 N2 1 1 1]);
M = cat(2, Yavg1(:,1,:,:,:), Yavg2(:,1,:,:,:));
clear Y*
S = ndfun('mult', d1, permute(d1, [2 1 3:5])) + ndfun('mult', d2, permute(d2, [2 1 3:5]));
outmask = repmat(shiftdim(~mask, -2), [p p 1 1 1]);
S(outmask) = 0;
outmask = repmat(eye(p), [1 1 size(mask)]) & outmask;
S(outmask) = 1;
b = ndfun('backslash', S, davg);
b = ndfun('mult', permute(davg, [2 1 3:5]), b);
T = b * N1*N2/(N1+N2) * (N1+N2-p-1)/p;

% Adjust output
T = permute(T, [3 4 5 1 2]);
M = permute(M, [3 4 5 1 2]);
S = permute(S, [3 4 5 1 2]);
if Ind,
    T = shiftdim(T, 2);
    M = shiftdim(M, 2);
    S = shiftdim(S, 2);
end

return
