function C = glm_determine_noise(Y,E,tr)
% Estimate the noise covariance for each voxel using its time series
%
%    C = glm_determine_noise(Y,E,tr):
%
% This routine is called when we try to whiten the noise in the
% event-related GLM tools.
%
% Given a matrix of time series, Y, and an estimated error for each voxel,
% E, and a frame period, tr, estimate the temporal noise covariance matrix
% for each voxel, C.
%
% Size of each argument:
% Input: Y: # Time Points x # Voxels x # Runs
%        E: 
%        tr: single integer
% Output: C: # Predictors x # Predictors x # Runs
%         The # of predictors is the total # of
%         different predictors in a GLM, including
%         DC baseline estimate predictors and, if
%         a selective-averaging GLM is being applied,
%         all nh hemodynamic predictors for each condition.
%         (The # predictors is the # of columns in the
%         design matrix produced by er_createDesMtx.)
%
%
% original code by gb, 11/04:
% updated by ras, 05/05

if nargin<3, help(mfilename); error('Insufficient args.'); end
    
% params
delayRange = 20; % # of seconds over which to estimate noise 
kmax = floor(delayRange / tr);
nFrames = size(E,1);
nSlices = size(E,2);

% use a heuristic to select voxels within the skull:
withinSkullVoxels = glm_choose_voxels(Y);

% estimate the autocorrelation within these
% voxels over the selected delay range (e.g., 20 secs):
B = E(:,withinSkullVoxels); % voxels in brain
for k = 1:kmax
    corr(k,:) = sum(B(1:nFrames-k,:).*B(k+1:nFrames,:))/sum(B.^2);
end
corr = mean(corr,2);

% Determine the parameters alpha and rho using in estimating the
% autocorrelation of residual errors (Re). These parameters will be used in
% the estimation function:
% Re(k) = 1,  k=0;
%         (1-alpha) * rho^k, 0 < |k| <= kmax
%         0, |k| > kmax
% This is equation (5) in the Burock and Dale 2000 paper, and eq. (13) in
% the Greve FS-FAST theory paper.
kmax = length(corr);

[x eval] = fminsearch(@glm_fit_model, [0, 1/2], optimset('TolX',1e-8),kmax,corr);
alpha = x(1);
rho   = x(2);

% finally, compute the noise covariance matrix:
tmp = [1 ((1 - alpha)*(rho.^(1:kmax))) zeros(1,nFrames - kmax - 1)];
C = toeplitz(tmp);

return
% /-----------------------------------------------------/ %


% sum(E(1:nFrames-k,:).*e(k+1:nFrames,:))/sum(E.^2);

