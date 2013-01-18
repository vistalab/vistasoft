function y = glm_fit_model(x,k,v);
%
% y = glm_fit_model(x,k,v);
%
% A model used to generate a 'synthetic' 
% autocorrelation function which may estimate
% temporally-correlated noise for within-
% skull voxels: see Burock and Dale, HBM 2000
% for more info.
%
% This is just broken off as a separate function
% for use in calling matlab's fminsearch routine.
%
% original code by gb, 11/04
% updated by ras, 05/05
y = norm((1 - x(1))*(x(2).^(1:k)') - v)^2;

return
