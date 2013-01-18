function K = dtiDirConcentration(S, mask)

% Computes voxel-wise concentration parameter corresponding to the Watson
% distribution from an array of direction dispersions.
%
%   K = dtiDirConcentration(S, [MASK])
%
% Input:
%   S           XxYxZx1 array of dispersions (NaN where MASK = 0)
%   MASK        Optional XxYxZ binary array. Values of K are computed where MASK = 1;
%                   in other voxels, K is set to NaN. Default is entire volume.
%
% Output:
%   K           XxYxZx1 array of concentration parameters (NaN where mask = 0)
%
% WARNING: If using Pentium 4, eliminate NaN's from array before running
% (processor bug).
%
% See also:
%   dtiDirConcFun
%
% Copyright by Armin Schwartzman, 2004

% HISTORY:
%   2004.07.22 ASH (armins@stanford.edu) wrote it.
%

if (~exist('mask')),
    mask = prod(ones(size(S)), 4);
    fprintf('Warning: no mask provided\n');
end

sz = size(S);
if (length(sz)>3),
    error('Wrong input format');
end

% Make look up table
imask = find(mask);
s = logspace(log10(min(S(imask))),log10(max(S(imask))));
k = dtiDirConcFun(s);

% Look up concentrations
Ktmp = interp1(s,k,S(imask));
K = NaN * ones(size(S));
K(imask) = Ktmp;

return
