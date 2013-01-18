function T = fiberTensors(fiber,D)
% Calculate a tensor for forward modeling at each node along a fiber.
%
%  T = fiberTensors(fibersImg,D)
%
% T is a matrix (numNodes X 9) of tensors at each node along the fiber.
%
% To put the tensor into the quadratic form, use T = reshape(T,3,3);
% eigs(T) calculates the axial diffusivity (largest) and so forth.
%
% Example:
%  d_ad = 1.5; d_rd = 0.3;
%  dParms(1) = d_ad; dParms(2) = d_rd; dParms(3) = d_rd;
%  D       = diag(dParms);    % The diagonal form of the Tensors' model
%                               parameters.
%  T = fiberTensors(fgImg,D)
%
% See also: fgTensors.m
%
% Franco (c) 2012 Stanford VISTA Team

% Compute the diffusion gradient at each node of the fiber.
fiberGradient = gradient(fiber);

% Number of nodes fro this fiber
numNodes = size(fiber,2);

% preallocated memory for the vector representation of tensors.
T = zeros(numNodes,9);

% Handling parallel processing
poolwasopen=1; % if a matlabpool was open already we do not open nor close one
if (matlabpool('size') == 0), matlabpool open; poolwasopen=0; end

parfor jj = 1:numNodes
 % Rotate the tensor toward the gradient of the fiber.
 %
 % Calculate a rotation matrix for the tensor so that points in the fiberGradient
 % direction and has two perpendicular directions (U)
 % Leaving the 3 outputs for this function is the fastest use of it.
 [Rot,~, ~] = svd(fiberGradient(:,jj)); % Compute the eigen vectors of the gradient.
 
 % Create the quadratic form of the tensor.
 %
 % The principal eigenvector is in the same direction of the
 % fiberGradient. The direction of the other two are scaled by dParms.
 % Human friendly version fo the code:
 % tensor = Rot*D*Rot'; % tensor for the current node, 3x3 matrix.
 % T(jj,:) = reshape(tensor,1,9); % reshaped as a vector 1,9 vector
 T(jj,:) = reshape(Rot*D*Rot',1,9);
end

if ~poolwasopen, matlabpool close; end

return