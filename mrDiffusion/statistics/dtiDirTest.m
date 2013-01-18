function [T, DISTR, df, M, S] = dtiDirTest(Sbar1, N1, Sbar2, N2)

% Computes voxel-wise directional test statistics of two groups.
%
%   [T, DISTR, df, M, S] = dtiDirTest(Sbar1, N1, Sbar2, [N2])
%
% Input:
%   Sbar1, Sbar2    XxYxZx6 (or nx6) arrays of scatter matrices for each group in dt6 format.
%                   X, Y, Z are the volume dimensions (n is the number of voxels).
%   N1, N2          Number of subjects in each group (N2 defaults to 1).
%
% Output:
%   T               XxYxZx1 (or nx1) array of test statistics.
%   DISTR           The string 'f'
%   df              The degrees of freedom of the f distribution
%   M               XxYxZx3 (or nx3) array of pooled mean directions
%   S               XxYxZx1 (or nx1) array of pooled dispersions
%
% Utilities:    ndfun.m, dtiEig.m, dti33to6.m
%
% WARNING: If using Pentium 4, eliminate NaN's from array before running
% (processor bug).
%
% E.g.:
%   [vec,val] = dtiEig(dt6);
%   [M, S, N, Sbar1] = dtiDirMean(squeeze(vec(:,:,1,1:6)));
%   [M1, S1, N1, Sbar2] = dtiDirMean(squeeze(vec(:,:,1,7)));
%   [T, DISTR, df] = dtiDirTest(Sbar, N, Sbar1);
%
% Reference:
%   A. Schwartzman, R. F. Dougherty, J. E. Taylor (2005),
%       "Cross-subject comparison of principal diffusion direction maps",
%       Magnetic Resonance in Medicine 53(6):1423-1431.
%
% Copyright by Armin Schwartzman, 2004

% HISTORY:
%   2004.06.23 ASH (armins@stanford.edu) wrote it.
%   2006.07.18 ASH added indexed format capability.
%   2006.07.25 ASH changed input parameters.

% Check inputs
if ~exist('N2'),
    N2 = 1;
end
if ((ndims(Sbar1)==2) & (ndims(Sbar2)==2)),
    Ind = 1;    % Data in indexed nx6 format
    Sbar1 = shiftdim(Sbar1, -2);
    Sbar2 = shiftdim(Sbar2, -2);
elseif ((ndims(Sbar1)==4) & (ndims(Sbar2)==4)),
    Ind = 0;    % Data in XxYxZx6 format
else
    error('Wrong input format');
end

% Constants
N  = N1 + N2;
p = 3;
DISTR = 'f';
df = [p-1, (p-1)*(N-2)];

Sbar = (N1 * Sbar1 + N2 * Sbar2)/(N1 + N2);
[vec1, val1] = dtiEig(Sbar1); % ndfun('eig', Sbar1);
[vec2, val2] = dtiEig(Sbar2); % ndfun('eig', Sbar2);
[vec, val] = dtiEig(Sbar); % ndfun('eig', Sbar);
M = vec(:,:,:,:,1);
S = (N - N1*val1(:,:,:,1) - N2*val2(:,:,:,1)) / (N-2);
T = (N1*val1(:,:,:,1) + N2*val2(:,:,:,1) - N*val(:,:,:,1)) ./ S;

% Adjust output
if Ind,
    T = shiftdim(T, 2);
    M = shiftdim(M, 2);
    S = shiftdim(S, 2);
end

return
