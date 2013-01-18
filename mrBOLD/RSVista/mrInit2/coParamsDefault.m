function p = coParamsDefault;
% Default Parameters for coherence analysis ("blocked analysis").
%
% params = coParamsDefault;
%
% This is an update of the 'blockedAnalysisParams' field in
% CreateNewDataTypes, created for mrInit2. 
%
% In addition to the previous fields which set time series detrend options 
% and the number of cycles for the corAnal, this function adds a few extra 
% parameters:
%
% * it explicitly adds the noiseBand field, which is used
%	for determining the noise level during a coherence analysis;
% * it adds a 'framesToUse' field, which can be used for computing
%	a corAnal on only a subset of frames (for isntance, if there 
%	are baseline periods before or after the main cycles.)
%
%
%
% ras, 07/2007.

% flag to do 'blocked' analysis --
% this is also relevant beyond simply enabling the corAnal.
% When preprocessing time series on the fly (e.g., for plotting
% the mean time series), the detrend option is taken from here if
% this flag=1, but from the 'event' (GLM) params if the flag=0. 
p.blockedAnalysis = 1;

% time series detrend options:
% -1: linear
%  0: no detrend
%  1: high-pass filter (removeBaseline2) 
%  2: quadratic trend removal
p.detrend = 1;

% inhomogeneity correction flag:     
%-------------------------------
%     0 do nothing
%     1 divide by the mean, independently at each voxel
%     2 divide by null condition
%     3 divide by anything you like, e.g., robust estimate of intensity
%     inhomogeneity
p.inhomoCorrect = 1;

% temporal normalization flag: 
p.temporalNormalization = 0;

% # cycles for (single-frequency) coherence analysis 
p.nCycles = 6;

% noise band indices for coherence analysis --
% this indicates what frequencies in a time series are 
% used to determine the noise level, which determines how
% large the 'co' (coherence) field is in a corAnal.
% (default 0, use all frequencies to determine the noise level)
p.noiseBand = 0;

% frames to use:
p.framesToUse = []; % empty--use all frames

return
