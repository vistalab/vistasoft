function [T, DISTR, df, M, S, T_VecUnscaled] = dtiLogTensorTest(TEST_TYPE, M1, S1, N1, M2, S2, N2)
% Computes voxel-wise test statistics for two groups.
%
%   [T, DISTR, df, M, S] = dtiLogTensorTest(TEST_TYPE, M1, S1, N1, M2, [S2], [N2])
%
% Input:
%   TEST_TYPE   (Optional) Controls the type of test (assuming equal variances
%                       between the two groups):
%                   'full': H0: both groups have the same mean tensors.
%                   'val' : H0: both groups have the same eigenvalues,
%                           with possibly different unknown eigenvectors.
%                   'vec' : H0: both groups have the same eigenvectors,
%                           but common unknown eigenvalues.
%   M1, M2      XxYxZx6 (or nx6) arrays of mean log-tensors for each group.
%                   X, Y, Z are the volume dimensions (n is the number of voxels).
%   S1, S2      XxYxZx1 (or nx1) arrays of standard deviations for each group.
%                   S2 is not needed if the second group consists of a single subject.
%   N1, N2      Number of subjects in each group (N2 defaults to 1).
%
% Output:
%   T           XxYxZx1 (or nx1) array of test statistics
%   DISTR       The character 'f'
%   df          degrees of freedom of the appropriate distribution
%   M           XxYxZx6 (or nx6) array of pooled mean log-tensors in dt6 format
%   S           XxYxZx1 (or nx1) array of pooled standard deviations
%
% Utilities:    dtiEig.m
%
% Examples:
%   % One-sample test:
%   [vec,val] = dtiEig(dt6);
%   val = log(val);
%   dt6 = dtiEigComp(vec,val);
%   [M, S, N] = dtiLogTensorMean(logDt6);
%   % logDt6_ss belongs to single subject
%   [T, DISTR, df] = dtiLogTensorTest('vec', M, sqrt(S), N, logDt6_ss);
%
%   % Two-sample test
%   [vec,val] = dtiEig(dt6_samp1);
%   [M1, S1, N1] = dtiLogTensorMean(dtiEigComp(vec,log(val)));
%   [vec,val] = dtiEig(dt6_samp2);
%   [M2, S2, N2] = dtiLogTensorMean(dtiEigComp(vec,log(val)));
%   [T, DISTR, df] = dtiLogTensorTest('vec', M1, sqrt(S1), N1, M2, sqrt(S2), N2);
%
% WARNING: If using Pentium 4, eliminate NaN's from array before running
% (processor bug).
%
% Reference:
%   A. Schwartzman, R. F. Dougherty, J. E. Taylor (2006),
%       "Statistical analysis tools for the full diffusion tensor: a log-normal approach",
%       Magnetic Resonance in Medicine (submitted).
%
% Copyright by Armin Schwartzman, 2006

% HISTORY:
%   2006.07.25 ASH (armins@stanford.edu) wrote it, combining previous functions
%       dtiTsqTestStat.m, dtiValTestStat.m, dtiVecTestStat.m
%
%       "Statistical analysis tools for the full diffusion tensor: a log-normal approach",
%       Magnetic Resonance in Medicine (submitted).
%
% Copyright by Armin Schwartzman, 2006

% HISTORY:
%   2006.07.25 ASH (armins@stanford.edu) wrote it, combining previous functions
%       dtiTsqTestStat.m, dtiValTestStat.m, dtiVecTestStat.m
%

% Check inputs
if ~exist('S2'),
    S2 = 0;
end

% Check inputs
if ~exist('S2'),
    S2 = 0;
end
if ~exist('N2'),
    N2 = 1;
end
if ((ndims(M1)==2) && (ndims(S1)==2) && (ndims(M2)==2) && (ndims(S2)==2)),
    Ind = 1;    % Data in indexed nx6 format
    M1 = shiftdim(M1, -2);
    S1 = shiftdim(S1, -2);
    M2 = shiftdim(M2, -2);
    S2 = shiftdim(S2, -2);
elseif ((ndims(M1)==4) && (ndims(S1)==3 || ndims(S1)==2) && ...
        (ndims(M2)==4) && (ndims(S2)==3 || ndims(S2)==2)),
    Ind = 0;    % Data in XxYxZx6 format
else
    error('Wrong input format');
end

% Constants
N  = N1 + N2;
q = size(M1, 4);                % should be 6
p = max(roots([1/2 1/2 -q]));   % should be 3

% Pooled mean
M = (N1*M1 + N2*M2)/N;

% Test type
switch TEST_TYPE,
    case 'full',
        T = N1*N2/N * sum((M1 - M2).^2, 4);  % This is chi^2(q) ***
        df(1) = q;
    case 'val',
        [V1,L1] = dtiEig(M1);
        [V2,L2] = dtiEig(M2);
        [V,L] = dtiEig(M);
        T = N1*N2/N * sum((L1 - L2).^2, 4);  % This is chi^2(p)
        df(1) = p;
    case 'vec',
        [V1,L1] = dtiEig(M1);
        [V2,L2] = dtiEig(M2);
        [V,L] = dtiEig(M);
        T_VecUnscaled = N * sum(((N1*L1 + N2*L2)/N).^2 - L.^2, 4);  % This is chi^2(q-p)
        T = T_VecUnscaled; 
        df(1) = q-p;
end

% Total variance
S = ((N1-1)*S1 + (N2-1)*S2)/(N-2);
df(2) = q*(N-2);
T = df(2)/df(1) * T./(q*(N-2)*S);

% Adjust output
DISTR = 'f';
if Ind,
    T = shiftdim(T, 2);
    M = shiftdim(M, 2);
    S = shiftdim(S, 2);
end

return
