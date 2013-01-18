function [M, S, N, Sbar] = dtiDirMean(Y)

% Computes voxel-wise mean directions and dispersions from a data
% array of DTI directions.
%
%   [M, S, N, Sbar] = dtiDirMean(DIR_ARRAY)
%
% Input:
%   DIR_ARRAY  Data array of size XxYxZx3xN (or nx3xN), where X,
%              Y, Z are the volume dimensions and N is the number
%              of subjects. The directions are contained in the
%              dimension of size 3.
%
% Output:
%   M          XxYxZx3 (or nx3) array of mean directions
%   S          XxYxZx1 (or nx1) array of dispersions
%   N          Number of subjects used in the computation of the dispersion
%   Sbar       XxYxZx6 (or nx3) array of scatter matrices in dt6 format
%
% To convert the dispersion (S) from arbitrary units into an angle:
%
%    dispersionDegrees = asin(sqrt(S))./pi.*180;
%
% Dependencies:    ndfun.m, dtiEig.m, dti33to6.m
%
% WARNING: If using Pentium 4, eliminate NaN's from array before running
% (processor bug).
%
% E.G.:
%   % Assume dt6 is a Mx6xN array of tensors for M voxels in N subjects:
%   [vec,val] = dtiEig(dt6);
%   % Compute the dispersion of the first eigenvector:
%   vec = permute(vec(:,:,1,:),[1 2 4 3]); % safer than 'squeeze'
%   [M, S, N, Sbar] = dtiDirMean(vec);
%
% Reference:
%   A. Schwartzman, R. F. Dougherty, J. E. Taylor (2005),
%       "Cross-subject comparison of principal diffusion direction maps",
%       Magnetic Resonance in Medicine 53(6):1423-1431.
%
% Copyright by Armin Schwartzman, 2004

% HISTORY:
%   2004.06.23 ASH (armins@stanford.edu) wrote it.
%   2006.07.25 ASH added indexed format capability and Sbar output.
%

% Check inputs
if(numel(Y)==3)
    M = squeeze(Y); M = M(:)';
    S = 0;
    N = 1;
    Sbar = NaN;
    return;
end

if (ndims(Y)==2 || ndims(Y)==3),
    Ind = 1;    % Data in indexed nx6xN format
    Y = shiftdim(Y, -2);
else
    Ind = 0;    % Data in XxYxZx6xN format
end
if (ndims(Y)<4 || ndims(Y)>5),
    error('Wrong input format');
end

N = size(Y, 5);
p = size(Y, 4); % should be 3


Y = permute(Y, [4 6 5 1:3]); % permutation required by ndfun
Sbar = sum(ndfun('mult', Y, permute(Y, [2 1 3:6])), 3) / N;
Sbar = dti33to6(permute(Sbar, [4:6 1:3]));
[vec, val] = dtiEig(Sbar);
M = vec(:,:,:,:,1);
S = (N - N*val(:,:,:,1));
if N>1,
    S = S / (N-1);
else
    S = S * NaN;
end

% Adjust output
if Ind,
    M = shiftdim(M, 2);
    S = shiftdim(S, 2);
    Sbar = shiftdim(Sbar, 2);
end

return
