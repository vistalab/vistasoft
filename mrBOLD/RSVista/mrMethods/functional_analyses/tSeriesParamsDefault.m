function params = tSeriesParamsDefault;
% Default signal-processing parameters for time series fMRI data.
%
% params = tSeriesParamsDefault;
%
% This is a rough adaptation of the mrVista 1.0 params. But,
% I expect this to be updated significantly. It should, add least,
% include more explicit specification of desired high- and 
% low-pass frequency filtering cutoffs. (Currently this is only
% achieved by setting detrend = 1 and setting the detrend frames
% to 1/[desired high-pass cutoff] for an approximate high-pass detrend
% using multiple boxcar smoothing.)
%
% Conversely, if the preprocessing done by mrDetrend is satisfactory,
% then we may want to ditch the whole idea of having separate tSeries
% methods, and assume all mr objects w/ time series data have already
% been pre-processed. 
%
% ras, 08/05

% Detrend options: integer w/ following values
% 0: Don't Detrend
% 1: Detrend w/ multiple boxcar smoothing
% 2: Linear Trend Removal
% 3: Quartic Trend Removal
params.detrend = 1;

% frames to use as period for boxcar detrending
params.detrendFrames = 20; 

% Options for how to compensate for distance from the coil, depending
% on the value of inhomoCorrection 
%   0 do nothing
%   1 divide by the mean, independently at each voxel
%   2 divide by null condition
%   3 divide by anything you like, e.g., robust estimate of intensity
%   inhomogeneity
params.inhomoCorrect = 1;

% temporal normalization: 
% if 1, normalize each frame to have same mean intensity
params.temporalNormalization = 0;

% subtract the mean: 
% if 1, subtract the mean, setting the overall mean to 0,
% if 0, don't do this
params.subtractMean = 1;


return
