function indexes = glm_choose_voxels(y);
%
% indexes = glm_choose_voxels(y);
%
% For Event-Related GLM tools:
% Use a very crude heuristic to choose 
% voxels "within the skull", to use
% in estimating noise covariance across
% voxels. (This is if the glm function
% is run with a "whiten" flag.)
%
% This heuristic is based on the one
% used by fs-fast: choose voxels whose 
% mean intensity across the time series
% y is greater than half the mean value.
%
% original code by gb, 11/04
% updated by ras, 05/05

% average across time, runs (1st & 3rd dimensions)
y = mean(y,3);
y = mean(y,1);

threshold = mean(y);
indexes = find(y > threshold);

% indexes = 1:size(y,2);

return
