function h_hat = glm_hdr_noise(X,C,y,nScans);
%
% h_hat = glm_hdr_noise(X,C,y,nScans);
%
% For Event-Related GLM tools:
% Given a time series y, a design matrix X,
% and an estimated voxel-independent noise
% covariance matrix C, compute the estimated 
% hemodynamic response to different conditions.
%
%
% original code by gb, 11/04
% updated by ras, 05/05
Xr = [];
yr = [];

for s = 1:nScans

    R = chol(C(:,:,s));
    R = (R')^(-1);
    
    Xr = vertcat(Xr,R * X(:,:,s));
    yr = vertcat(yr,R * y(:,:,s));
    
end

h_hat = pinv(Xr)*yr;

return
