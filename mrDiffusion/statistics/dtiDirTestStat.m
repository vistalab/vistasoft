function [T, M, S, DISTR, df] = dtiDirTestStat(g1, g2, Y, mask)

% Computes voxel-wise test statistics for two groups from a data array of
% DTI directions.
%
%   [T, M, S, DISTR, df] = dtiDirTestStat(g1, g2, DIR_ARRAY, [MASK])
%
% Input:
%   g1, g2      List of indices that correspond to each group out of 1:N
%                   E.g: g1 = 1:7, g2 = 8:14, N = 14
%   DIR_ARRAY   Data array of size XxYxZx3xN (or nx3xN), where X, Y, Z are the volume
%                   dimensions and N is the number of subjects.
%                   The directions are contained in the dimension of size 3.
%   MASK        Optional XxYxZ binary array. Values of M and S are computed
%                   where mask = 1; in other voxels, M and S are set to NaN.
%                   Default is entire volume.
%
% Output:
%   T           XxYxZx1 (or nx1) array of test statistics (NaN where mask = 0)
%   M           XxYxZx3x2 (or nx3x2) array of mean directions for both groups (NaN where mask = 0)
%   S           XxYxZx1 (or nx1) array of dispersions (NaN where mask = 0)
%   DISTR       The string 'f'
%   df          The degrees of freedom of the f distribution
%
% Utilities:    ndfun.m, dtiEig.m, dti33to6.m
%
% WARNING: If using Pentium 4, eliminate NaN's from array before running
% (processor bug).
%
% Copyright by Armin Schwartzman, 2004

% HISTORY:
%   2004.06.23 ASH (armins@stanford.edu) wrote it.
%   2006.07.18 ASH (armins@stanford.edu) added indexed format capability.
%

% Check inputs
if (ndims(Y)==2 | ndims(Y)==3),
    Ind = 1;    % Data in indexed nx3xN format
    Y = shiftdim(Y, -2);
else
    Ind = 0;    % Data in XxYxZx3xN format
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
p = size(Y, 4); % should be 3
DISTR = 'f';
df = [p-1, (p-1)*(N-2)];

Y = permute(Y, [4 6 5 1 2 3]); % permutation required by ndfun
Tbar1 = shiftdim(sum(ndfun('mult', Y(:,1,g1,:,:,:), permute(Y(:,1,g1,:,:,:), [2 1 3:6])), 3), 3) / N1;
Tbar2 = shiftdim(sum(ndfun('mult', Y(:,1,g2,:,:,:), permute(Y(:,1,g2,:,:,:), [2 1 3:6])), 3), 3) / N2;
Tbar = (N1 * Tbar1 + N2 * Tbar2)/(N1 + N2);
[vec1, val1] = dtiEig(dti33to6(Tbar1)); % ndfun('eig', Tbar1);
[vec2, val2] = dtiEig(dti33to6(Tbar2)); % ndfun('eig', Tbar2);
[vec, val] = dtiEig(dti33to6(Tbar)); % ndfun('eig', Tbar);
M = cat(5, vec1(:,:,:,:,1), vec2(:,:,:,:,1));
S = (N - N1*val1(:,:,:,1) - N2*val2(:,:,:,1)) / (N-2);;
T = (N1*val1(:,:,:,1) + N2*val2(:,:,:,1) - N*val(:,:,:,1)) ./ S;
M(~repmat(mask,[1 1 1 3 2])) = NaN;
S(~mask) = NaN;
T(~mask) = NaN;

% Adjust output
if Ind,
    T = shiftdim(T, 2);
    M = shiftdim(M, 2);
    S = shiftdim(S, 2);
end

return