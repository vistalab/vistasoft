function [M, S, N, T, df] = dtiLogTensorMean(Y, COV_TYPE)

% Computes voxel-wise mean and variance from a data array of
% log-diffusion tensors in dt6 format.
% Covariance structure can be spherical, rotation-invariant or full, 
%
  %   [M, S, N, T, df] = dtiLogTensorMean(DT_ARRAY, COV_TYPE)
%
% Input:
%   DT_ARRAY    Data array of size XxYxZx6xN (or nx6xN), where X, Y, Z are the
%                   volume dimensions and N is the number of subjects.
%                   (n is the number of voxels).
%   COV_TYPE    Type of covariance: 'spherical' (default), 'rot-inv' or 'full'.
%
% Output:
%   M           XxYxZx6x2 (or nx6x2) array of mean log-tensors in dt6 format
%   S           XxYxZx1 (or nx1) array of variances ('spherical')
%               XxYxZx2 (or nx2) array of variances and diagonal covariances ('rot-inv').
%               XxYxZx6x6 (or nx6x6) array of covariance matrices ('full').
%   N           Number of subjects used in the computations.
%   T           Test statistic for testing if covariance is of type COV_TYPE vs. full.
%   df          Degrees of freedom for the test.
%
% E.g.:
%   [vec,val] = dtiEig(dt6);
%   val = log(val);
%   logDt6 = dtiEigComp(vec,val);
%   [M, S, N] = dtiLogTensorMean(logDt6);
%
%
% NOTE: the previous version of this function returned the standard deviation in S. 
% The current version returnes the vVARIANCE in S. To get the old S, run:
%   [M, S, N, T, df] = dtiLogTensorMean(Y, 'spherical');
%   S = sqrt(S);
%
%
% Copyright by Armin Schwartzman, 2006

% HISTORY:
%   2006.07.21 ASH (armins@stanford.edu) wrote it.
%   2008.01.?? ASH added COV_TYPE options and changed output of S.

% Check inputs
if ~exist('COV_TYPE'), COV_TYPE = 'spherical'; end
if (~strmatch(COV_TYPE,'spherical') && ~strmatch(COV_TYPE,'rot-inv') && ~strmatch(COV_TYPE,'full')),
    error('Only spherical, rot-inv and full covariance types supported.')
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

% Constants
N = size(Y,5);
q = size(Y, 4);                 % should be 6
p = (-1 + sqrt(1+8*q))/2;       % should be 3
if p ~= round(p),
    error('size of M must be p(p+1)/2 for some integer p')
end
qq = q*(q+1)/2;

if (N <= qq),
    warning('Not enough subjects to estimate full covariance')
end

% Mean
M = mean(Y,5);

% Covariance
d = Y - repmat(M,[1 1 1 1 N]);
d(:,:,:,p+1:q,:) = sqrt(2)*d(:,:,:,p+1:q,:);
Sfull = permute(sum(ndfun('mult', permute(d, [4 6 5 1:3]), permute(d, [6 4 5 1:3])), 3), [4:6 1:3])/(N-1);
detSfull = permute(ndfunm('det',permute(Sfull*(N-1)/N, [4:5 1:3])), [2:4 1]);

switch COV_TYPE,
case 'spherical',
    S = sum(sum(d.^2, 4), 5)/(q*(N-1));
    T = N*q*log(S*(N-1)/N) - N*log(detSfull);
    df = qq - 1;
case 'rot-inv',
    trc2 = sum(sum(d.^2, 4),5);
    tr2 = sum(sum(d(:,:,:,1:p,:), 4).^2, 5);
    tau = -(trc2 - (q/p)*tr2)./((q-1)*tr2);
    S = cat(4, (trc2 - tau.*tr2)/(q*(N-1)), tau);
    T = N*q*log(S(:,:,:,1)*(N-1)/N) - N*log(1 - p*S(:,:,:,2)) - N*log(detSfull);
    df = qq - 2;
case 'full',
    S = Sfull;
    T = 0;
    df = 0;
end

% Adjust output
if Ind,
    M = shiftdim(M, 2);
    S = shiftdim(S, 2);
    T = shiftdim(T, 2);
end

return


%------------------------------------------------------------------------
% Debugging
M = zeros(1,6);
S = shiftdim(diag([1 1 1 1/2 1/2 1/2]), -1);
X = dtiSymNormal2(M, S, 1000);
[Mhat, Shat, N, T, df] = dtiLogTensorMean2(X);
[Mhat, Shat, N, T, df] = dtiLogTensorMean2(X, 'rot-inv');
[Mhat, Shat, N, T, df] = dtiLogTensorMean2(X, 'full');
Mhat, squeeze(Shat), N, T, df

n = 1000;
N = 30;
X = dtiSymNormal2(repmat(M, [n 1]), repmat(S, [n 1 1]), N);
[Mhat, Shat, N, T, df] = dtiLogTensorMean2(X, 'rot-inv');

