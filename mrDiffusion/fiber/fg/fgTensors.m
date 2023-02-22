function Q = fgTensors(fg,dParms)
%Calculate a tensor for forward modeling at each point of each fiber
%
%  Q = fgTensors(fgImg,dParms)
%
% Q is a cell array of the same length as the number of fibers
% Each Q{ii} contains a matrix of (numNodes x 9) tensors.
%
% To put the tensor into the quadratic form, use T = reshape(T,3,3);
% eigs(T) calculates the axial diffusivity (largest) and so forth.
%
% Example:
%  d_ad = 1.5; d_rd = 0.3;
%  dParms(1) = d_ad; dParms(2) = d_rd; dParms(3) = d_rd;
%  fgImg.Q = fgTensors(fgImg,dParms)
%
% See also: s_mictSimples (vistaproj/microtrack), mctDiffusionModel
%
% (c) 2012 Stanford VISTA Team

% Preallocate
nFibers = length(fg.fibers); % The number of Fibers.
Q       = cell(1,nFibers); % Memory for the tensors of each fiber.
D       = diag(dParms);    % The diagonal form of the Tensors' model parameters.

for ii = 1:nFibers
 % Compute the diffusion gradient at each node of the fiber.
 fiberGradient = gradient(fg.fibers{ii});
 
 % Number of nodes fro this fiber
 numNodes = size(fg.fibers{ii},2);
 
 % preallocated memory for the vector representation of tensors.
 T = zeros(numNodes,9);
 
 for jj = 1:numNodes
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
  T(jj,:) = reshape(Rot*D*Rot',1,9);
 end
 % T is a matrix; each row is a 1,9 version of the tensor.
 Q{ii} = T;
end

return

% function T = fiberTensors(fiber,D)
%
% % Compute the diffusion gradient at each node of the fiber.
% fiberGradient = gradient(fiber);
%
% % Number of nodes fro this fiber
% numNodes = size(fiber,2);
%
% % preallocated memory for the vector representation of tensors.
% T = zeros(numNodes,9);
% for jj = 1:numNodes
%  % Rotate the tensor toward the gradient of the fiber.
%  %
%  % Calculate a rotation matrix for the tensor so that points in the fiberGradient
%  % direction and has two perpendicular directions (U)
%  % Leaving the 3 outputs for this function is the fastest use of it.
%  [Rot,~, ~] = svd(fiberGradient(:,jj)); % Compute the eigen vectors of the gradient.
%
%  % Create the quadratic form of the tensor.
%  %
%  % The principal eigenvector is in the same direction of the
%  % fiberGradient. The direction of the other two are scaled by dParms.
%  % Human friendly version fo the code:
%  % tensor = Rot*D*Rot'; % tensor for the current node, 3x3 matrix.
%  % T(jj,:) = reshape(tensor,1,9); % reshaped as a vector 1,9 vector
%  T(jj,:) = reshape(Rot*D*Rot',1,9);
% end
