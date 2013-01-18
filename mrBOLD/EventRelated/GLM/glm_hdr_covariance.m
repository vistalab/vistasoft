function C_hs = hdr_covariance(X,C,nh,nScans);
%
% C_hs = hdr_covariance(X,C,nh,nScans);
%
% Event-Related GLM tools:
% Compute the voxel-independent factor of the
% covariance matrix of a general linear model.
% This is taken from eq. (16) in the Greve
% theory paper (FS-FAST).
% 
% original code by gb, 11/04:
% updated by ras, 05/05
C_hs = zeros(size(X,2));

for s = 1:nScans
    C_hs = C_hs + ((X(:,:,s)')*(C(:,:,s)^(-1))*X(:,:,s));
end

C_hs = C_hs^(-1);

return
