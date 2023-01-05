function glm = glmCreate(tr,nh,whiten)
%Create a GLM model for managing the GLM parameters
%
%   glm = glmCreate(tr,nh,whiten)
%
%

% It would be better to go and get the TR from the SESSION data.
if notDefined('tr'),     error('You must specify tr for the GLM'); end
if notDefined('nh'),     nh = 22; end
if notDefined('whiten'), whiten = 0; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize GLM model %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
glm.betas    = [];
glm.residual = [];
glm.stdevs   = [];
glm.sems     = [];
glm.nh       = nh;       % Number of time samples
glm.tr       = tr;       %
glm.C        = [];       % Covariance matrix
glm.voxDepNoise    = [];
glm.voxIndepNoise  = [];
glm.designMatrix   = [];
glm.dof            = []; % Degrees of freedom
glm.whiten         = whiten;  % Do not whiten the covariance

% glmSet() ...
if nh>1, glm.type = 'selective averaging';
else     glm.type = 'applied HRF';
end

return;
