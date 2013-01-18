function trial_cnt = glm_trialCount(X,nh);
%
% trial_cnt = glm_trialCount(X,nh);
%
% Count the # of trial onsets for each condition
% given a stimulus convolution matrix X.
% (For info on X, see delta_function_from_parfile).
%
% Written by ras 02/05.

% ensure X is 2D, size allTimePoints x conditions:
% (allTimePoints is ntp*nruns):
if ndims(X)==3
    % concat across several runs
    X = permute(X,[1 3 2]);
    X = reshape(X,[size(X,1)*size(X,2) size(X,3)]);
end

% then, just sum up:
% so if someone passed in a matrix X that
% had already been convolved with whatever
% impulse function they liked, they'd just need
% to ensure that the integral of each impulse was
% 1, as with the standard delta functions:
trial_cnt = sum(X,1);
trial_cnt = round(trial_cnt);

% for deconvolved data, there are nh redudant
% trial counts for each trial. Do a sanity check,
% and remove the redundant trials:
if nh > 1
    nConds = floor(length(trial_cnt)/nh);
    rng = 1:nh:nh*nConds;
    trial_cnt = trial_cnt(rng);
end

return
