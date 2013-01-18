function [M, S, N] = dtiLogTensorMeanOrig(Y)

% Computes voxel-wise mean and variance from a data array of
% log-diffusion tensors in dt6 format.
%
%   [M, S, N] = dtiLogTensorMean(DT_ARRAY)
%
% Input:
%   DT_ARRAY    Data array of size XxYxZx6xN (or nx6xN), where X, Y, Z are the volume
%                   dimensions and N is the number of subjects.
%                   (n is the number of voxels).
%
% Output:
%   M           XxYxZx6x2 (or nx6x2) array of mean log-tensors in dt6 format
%   S           XxYxZx1 (or nx1) array of standard deviations
%   N           Number of subjects used in the computation of the variance
%
% E.g.:
%   [vec,val] = dtiEig(dt6);
%   val = log(val);
%   logDt6 = dtiEigComp(vec,val);
%   [M, S, N] = dtiLogTensorMean(logDt6);
%
% Reference:
%   A. Schwartzman, R. F. Dougherty, J. E. Taylor (2006),
%       "Statistical analysis tools for the full diffusion tensor: a log-normal approach",
%       Magnetic Resonance in Medicine (submitted).
%
% Copyright by Armin Schwartzman, 2006

% HISTORY:
%   2006.07.21 ASH (armins@stanford.edu) wrote it.

% Check inputs
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
p = max(roots([1/2 1/2 -q]));   % should be 3

% Means
M = mean(Y,5);

% Total variance
d = Y - repmat(M,[1 1 1 1 N]);
S = sum(sum(d(:,:,:,1:p,:).^2, 4) + 2*sum(d(:,:,:,p+1:q,:).^2, 4),5);
S = sqrt(S/(q*(N-1)));

% Adjust output
if Ind,
    M = shiftdim(M, 2);
    S = shiftdim(S, 2);
end

return

