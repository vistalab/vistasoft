function [detJ,J] = dtiJacobian(inData)
%
% [detJ,J] = dtiJacobian(inData)
%
% Computes the Jacobian (J) and the determinant of the Jacobian (detJ)
% given an XxYxZx3 or Nx3 input array. The array is assumed to represent a
% vector field. The Jacobian is a useful metric for interpreting
% deformations. E.g., abs(detJ) represents the local volume change for a
% deformation field.
%
% HISTORY:
% 2008.06.25 RFD wrote it.

sz = size(inData);

if((numel(sz)~=4 && numel(sz)~=2) || sz(end)~=3)
    error('inData must be XxYxZx3 or Nx3.');
end

% Approximate the Jacobian of the input array using grad.

if(numel(sz)==2)
    inData = reshape(inData,[1 1 1 sz(1) sz(2)]);
end

dim = size(inData);
J = zeros(dim(1),dim(2),dim(3),3,3);

for(ii=1:3)
    [gradX,gradY,gradZ] = gradient(inData(:,:,:,ii),1);  
    J(:,:,:,ii,1) = gradX; 
    J(:,:,:,ii,2) = gradY; % Or Y,X,Z?
    J(:,:,:,ii,3) = gradZ;
end
% Compute the determinant of J
% det(J) for a 3x3 [a b c; d e f; g h i] is: (aei+bfg+cdh)-(gec+hfa+idb)
% a=1,1; b=1,2; c=1,3; d=2,1; e=2,2; f=2,3; g=3,1; h=3,2; i=3,3;
detJ =  J(:,:,:,1,1).*J(:,:,:,2,2).*J(:,:,:,3,3) ...
      + J(:,:,:,1,2).*J(:,:,:,2,3).*J(:,:,:,3,1) ...
      + J(:,:,:,1,3).*J(:,:,:,2,1).*J(:,:,:,3,2) ...
      - J(:,:,:,3,1).*J(:,:,:,2,2).*J(:,:,:,1,3) ...
      - J(:,:,:,3,2).*J(:,:,:,2,3).*J(:,:,:,1,1) ...
      - J(:,:,:,3,3).*J(:,:,:,2,1).*J(:,:,:,1,2);
  
if(numel(sz)==2)
    J = squeeze(J);
    detJ = squeeze(detJ);
end
return;