function [T, DISTR, df, M, S] = dtiTTest(M1, S1, N1, M2, S2, N2)
% Voxel-wise T-test statistics of two groups.
%
%  [T, DISTR, df, M, S] = dtiTTest(M1, S1, N1, M2, [S2], [N2])
%
% The T-value is group 1 minus group 2.  Thus, if we run
%      
%    [Tvalues, DISTR, df] = dtiTTest(atlasMean, atlasStd,atlasN, singleSubj);
%    [Tvalues, DISTR, df] = dtiTTest(atlas1Mean, atlas1Std,atlas1N, atlas2Mean);
%
% It is OK to have atlast2Mean be a single subject.
% Postive T-values mean atlas1 is bigger than atlas2 or the subject.
% Negative means atlas2 or the subject has higher mean diffusivity than the
% atlas1. 
%
% Input:
%   M1, M2      XxYxZx1 (or nx1) arrays of mean values for each group.
%                   X, Y, Z are the volume dimensions (n is the number of voxels).
%   S1, S2      XxYxZx1 (or nx1) arrays of standard deviations for each group.
%                   Not needed if the second group consists of a single subject.
%   N1, N2      Number of subjects in each group (N2 defaults to 1).
%
%
% Output:
%   T           XxYxZx1 array of test statistics (0 where mask = 0)
%   DISTR       The string 't'
%   df          The number of degrees of freedom = N-2
%   M           XxYxZx2 array of pooled means
%   S           XxYxZx1 array of pooled standard deviations
%
% Copyright by Armin Schwartzman, 2005

% HISTORY:
%   2004.06.23 ASH (armins@stanford.edu) wrote it.
%   2006.07.25 ASH changed input parameters.

% Check inputs
if ~exist('S2'),
    S2 = 0;
end
if ~exist('N2'),
    N2 = 1;
end
if ((ndims(M1)==2) & (ndims(S1)==2) & (ndims(M2)==2) & (ndims(S2)==2)),
    Ind = 1;    % Data in indexed nx6 format
    M1 = shiftdim(M1, -2);
    S1 = shiftdim(S1, -2);
    M2 = shiftdim(M2, -2);
    S2 = shiftdim(S2, -2);
elseif ((ndims(M1)==3) & (ndims(S1)==3) & ...
        (ndims(M2)==3) & (ndims(S2)==3)),
    Ind = 0;    % Data in XxYxZx6 format
else
    error('Wrong input format');
end

% Computations
N = N1 + N2;
M = (N1*M1 + N2*M2) / N;
S = sqrt(((N1-1)*S1.^2 + (N2-1)*S2.^2) / (N-2));
T = (M1 - M2) ./ (S * sqrt(1/N1 + 1/N2));

% Adjust output
if Ind,
    T = shiftdim(T, 2);
    M = shiftdim(M, 2);
    S = shiftdim(S, 2);
end

DISTR = 't';
df = [N-2 N-2];     % Second entry is dummy

return
