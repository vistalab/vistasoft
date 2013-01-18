function model = glm(Y, X, tr, nh, whiten, trial_count)
% Compute GLM for data in Y and design in X
%
%    model = glm(Y, X, [tr], [nh], [whiten], [trial_count]):
%
% Apply a general linear model to the time series in Y, using the
% experimental design information contained in X. 
%
% Y: matrix of time series data, of size nFrames by nVoxels,
% where 
%   nFrames = number of time points and 
%   nVoxels = # voxels.
% Will apply GLM to all these time series in one step.
%
% X: The Design Matrix.
%  The Design matrix (model.X) can be obtained by from either glm_createDesMtx, or
%  glm_deconvolution_matrix. 
%
%  In the glm_createDesMtx case, you are applying an estimated hemodynamic
%  response function to form the predictors for each condition.  The
%  estimate produces one beta value for each condition. 
%
%  If you call glm_deconvolution_matrix you are returned an estimated
%  response shape for each condition, by applying multiple (nh) predictors
%  for each conditions (the predictors get the response at different times
%  relative to trial onset). This is the approach followed in several
%  papers from the Dale lab, including HBM, 2000, and J. Cogn. Neurosci.,
%  2001. It essentially estimates a peri-stimulus time course for each
%  condition, with a separate beta for each time point relative to the
%  stimulus onset.
% 
% X is a 2-D matrix with rows = #MR frames by columns = #predictors.
% 
% The GLM returns one beta value and error estimate for each predictor,
% grouping every nh predictors together (see below).
%
% Optional Arguments:
%
% nh: # of time points in the estimated response to each
% condition. If you are applying an HRF, this should be
% set to 1. [default 1] 
%
% tr: frame period, in secs. [default 1 sec]
%
% whiten: if 1, will 'whiten' data by estimating noise
% covariance across voxels; otherwise will not. [Default 0]
%
% trial_count: specify the number of trials for each condition.
% This is used for estimating the "sem" (in model.sems) for each
% condition. If omitted, will guess the # of trials for each predictor
% based on the area under that predictor (column in X). I.e., If each
% event onset creates an impulse response with an area 1, this will be
% correct; otherwise this field may be incorrect.
%
% The output model struct includes the following fields:
%   betas: Rory says: estimated hemodynamic responses, 
%          In the case when nh=1, these are the linear model weights that
%          one applies to the design matrix to estimate the BOLD response.
%           size [nh by nPredictors by nVoxels]
%
%   residual: estimated error for each point in h_bar,
%           size [nFrames by nVoxels] 
%
%   stdevs: estimated standard deviation for each beta value
%           size [nh by nPredictors by nVoxels]
%
%   sems: standard error of the mean for beta values
%           size [nh by nPredictors by nVoxels ]
%
%   C: estimated (or assumed) noise covariance matrix. If whiten
%      is 0, you are assuming this is a (big) identity matrix; if it's 1,
%      we calculate the covariance from glm_determine_noise
%      [describe]
%
%   voxDepNoise: voxel-dependent noise estimate (No longer computed)
%           size [nVoxels by 1]
%
%   voxIndepNoise: voxel-independent component of autocorrelation
%       matrix of beta (linear model) weights. 
%       voxDepNoise * voxIndepNoise = the autocorrelation matrix.
%           size [nPredictors by nPredictors]
%           X is the design matrix, model.C is assumed noise covariance
%           matrix for the beta weights.  We assume ordinarily that these
%           are independent equal variance so that model.C is typically
%           treated as the identity matrix.  Hence the covariance of the
%           beta weights really depends only on the orthogonality or lack
%           thereof between the predictors in the design matrix.
%            = inv(X'* model.C * X)
%           Since model.C is usually the identity, this is no more than
%            = inv(X'*X)
%           When X is orothonormal, even this because the identity matrix.
%
%   dof: degrees of freedom of the fitting.
%
%
% For a reference on the noise covariance methods, see Burock and Dale,
% Human Brain Mapping, 11:249-260. (2000) or the Greve theory paper
% included w/ Freesurfer FS-FAST. Thanks to you guys for the background.
%
% Code written from scratch by ras and gb, early 2005.

% TODO:
%  Write modelSet, modelGet, modelCreate();
%  Maybe these should be glmSet/Get/Create?
%

if nargin < 2,				help glm, return;		end
if notDefined('tr'),		tr = 1;					end
if notDefined('nh'),		nh = 1;					end
if notDefined('whiten'),	whiten = 0;				end

% Time series are sometimes uint16 or float.  Here we force to double
if ~isa(Y,'double'),            Y = double(Y);      end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize model struct    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (ras -- not sure we should call an external function to create this.
% External function calls can still slow things down a bit, and the glm
% function is called pretty frequently in several analyses. Also, would we
% ever need to call glmCreate / glmSet outside of this function?)
model.betas = [];
model.residual = [];
model.stdevs = [];
model.sems = [];
model.nh = nh;
model.tr = tr;
model.C = [];
model.voxDepNoise = [];
model.voxIndepNoise = [];
model.designMatrix = [];
model.dof = [];
model.whiten = whiten;

if nh>1, model.type = 'selective averaging';
else     model.type = 'applied HRF';
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize: size check, etc                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nFrames = size(Y,1);
nVoxels = size(Y,2);
nPredictors = size(X,2);

if size(X,1)~=nFrames
    fprintf('Rows in Y: %i, Rows in X: %i\n',size(Y,1),size(X,1));
    error('X and Y should have the same number of rows.')
end
   
% Store
model.designMatrix = X;

% Compute Degrees of Freedom of model
% Rtmp = eye(nFrames) - X*pinv(X);     % Residual Error Forming Matrix 
model.dof = size(Y,1) - rank(X);       % trace(Rtmp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Estimate the weights (beta) of the predictors in the design matrix, X
% This calculation assumes white noise in the data. If there is structured
% noise (covariance) you can try to whiten the noise using the whiten flag
% (see below).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This is the same as model.betas = pinv(Y)*X;
% Which solves for Y = X*beta
%
model.betas = X\Y;    % hist(model.betas(1,:),100)

% Compute residual error of initial fitting
model.residual = Y - X*model.betas;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If selected, determine noise distribution and re-apply model %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if whiten==1
	% Estimate noise covariance matrix over time.
	model.C = glm_determine_noise(Y,model.residual,tr);
	
	% Using noise covariance matrix, recompute estimated responses 
%     R = chol(model.C);
%     R = (R')^(-1);
	R = model.C ^ (-1);
    model.betas = (X' * R * X) \ (X' * R * Y);

	% Recompute residual error  
	model.residual = Y - X*model.betas;
	
else
    % estimated noise covariance over time is an identity matrix
    model.C = eye(nFrames);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute factors of covariance matrix for the betas:          %
% sigma-squared is the voxel-dependent noise for each voxel,   %
% while voxIndepNoise is the voxel-independent covariance      %
% (Both on the rhs in Eq (16) of the Greve paper)              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Variance of residual error (voxel-dependent scalar)
% (Disabled, too memory-hungry, not hugely useful)
%   tmp = diag(model.residual' * inv(model.C) * model.residual)';
%   model.voxDepNoise = tmp ./ model.dof;


% Covariance matrix for the design matrix.  This is a voxel-independent
% matrix that summarizes the correlation between the design matrix
% predictors.  Usually model.C is just the identity matrix because we don't
% (in advance) have any particular believes about the covariance between
% the samples at different temporal sample times.  Hence, the only
% covariance that we extract is the covariance that is traced to the lack
% of orthogonality between the predictors.
model.voxIndepNoise = inv(X'* model.C * X);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Estimate Std. Deviation, SEMs for each beta value %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% estimated residual variance, std deviation
eres_var     = sum(model.residual.^2) / model.dof; 
eres_std     = sqrt(eres_var); 

% This is based on er_selxavg, line 377 (hstd):
model.stdevs = sqrt((diag(model.voxIndepNoise).*diag(X'*X)) * eres_std.^2);

% get SEMs: 
if ~exist('trial_count','var') || isempty(trial_count)
    model.trial_count = glm_trial_count(X, 1); % separate count / predictor
else
    model.trial_count = trial_count;
end

tmp = repmat(model.trial_count(:),[1 nVoxels]);
model.sems = model.stdevs ./ sqrt(tmp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reshape if necessary: Group every nh predictors %
% together in the main matrices                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nh > 1
    % there may be baseline predictors appended to
    % the design matrix: group these separately
    % NOTE: this assumes the number of DC predictors
    % is less than nh; if this is no longer a realistic
    % assumption, will need to fix this:
    nDC = mod(nPredictors,nh);
    if nDC > 0        
        dcRange = nPredictors-nDC+1:nPredictors;

        model.dc_betas  = model.betas(dcRange,:);
        model.dc_stdevs = model.stdevs(dcRange,:);
        model.dc_sems   = model.sems(dcRange,:);
        
        model.betas  = model.betas(1:dcRange(1)-1,:);
        model.stdevs = model.stdevs(1:dcRange(1)-1,:);
        model.sems   = model.sems(1:dcRange(1)-1,:);
    end
    
end

nConds = floor(nPredictors/nh);
model.betas = reshape(model.betas,[nh nConds nVoxels]);
model.stdevs = reshape(model.stdevs,[nh nConds nVoxels]);
model.sems = reshape(model.sems,[nh nConds nVoxels]);

return
