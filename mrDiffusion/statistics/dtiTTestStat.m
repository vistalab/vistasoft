function [T, M, S, DISTR, df] = dtiTTestStat(g1, g2, Y, mask)

% Computes voxel-wise T-test statistics for two groups from a data array.
%
%   [T, M, S, DISTR, df] = dtiTTestStat(g1, g2, DT_ARRAY, [MASK])
%
% Input:
%   g1, g2      List of indices that correspond to each group out of 1:N
%                   E.g: g1 = 1:7, g2 = 8:14, N = 14
%   DT_ARRAY    Data array of size XxYxZxN (or nxN), where X, Y, Z are the volume
%                   dimensions and N is the number of subjects.
%                   (n is the number of voxels).
%   MASK        Optional XxYxZ binary array. Values of M and S are computed
%                   where mask = 1; in other voxels, M and S are set to 0.
%                   Default is entire volume.
%
% Output:
%   T           XxYxZx1 array of test statistics (0 where mask = 0)
%   M           XxYxZx2 array of means for both groups (0 where mask = 0)
%   S           XxYxZx1 array of pooled standard deviations (0 where mask = 0)
%   DISTR       The string 't'
%   df          The number of degrees of freedom = N-2
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
    Ind = 1;    % Data in indexed nxN format
    Y = shiftdim(Y, -2);
else
    Ind = 0;    % Data in XxYxZxN format
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

M = cat(4, mean(Y(:,:,:,g1), 4), mean(Y(:,:,:,g2), 4));
Ystd1 = std(Y(:,:,:,g1), 1, 4); Ystd1(~mask) = 1;
Ystd2 = std(Y(:,:,:,g2), 1, 4); Ystd2(~mask) = 1;
S = sqrt((N1*Ystd1.^2 + N2*Ystd2.^2)/(N-2) .* (1/N1 + 1/N2));
T = (M(:,:,:,1) - M(:,:,:,2)) ./ S;

% Adjust output
if Ind,
    T = shiftdim(T, 2);
    M = shiftdim(M, 2);
    S = shiftdim(S, 2);
end

DISTR = 't';
df = [N-2 N-2];     % Second entry is dummy

return
