function params = er_defaultParams
%
%  params = er_defaultParams;
%
% Returns default parameters for running
% event-related analyses. Chose them
% to be nice for most KGS-lab block-design
% extps.
%
%
% ras 04/05.
% ras 11/06: added HRF sub-params (for standard H.R.F.s)
% dar 3/07    fixed typo in glmHRF_params, added comments on each parameter
params.eventAnalysis = 1; % back compatibility w/ mrLoadRet code

% detrend flag: 
%--------------
% -1 linear detrend, 0 no detrend, 1 multiple boxcar smoothing,
% 2 quartic trend removal
params.detrend = 1;

% detrend frames: 
% for detrend option 1, # of frames for smoothing
% kernal (roughly equivalent to cutoff of highpass
% filter):
params.detrendFrames = 20;

% inhomogeneity correction flag:     
%-------------------------------
%     0 do nothing
%     1 divide by the mean, independently at each voxel
%     2 divide by null condition
%     3 divide by spatial gradient estimate
params.inhomoCorrect = 1;

% temporal normalization flag: 
params.temporalNormalization = 0;

% seconds relative to trial onset to take for each trial
params.timeWindow = -8:24;

% period to look for peaks in t-tests, in seconds
params.peakPeriod = 4:14;

% period to use as baseline in t-tests, in seconds
params.bslPeriod = -8:0;

% threshold for significant activations
params.alpha = 0.05;

% # secs to shift onsets in parfiles, relative to time course
params.onsetDelta = 0;

% conditions to use for calculating signal-to-noise, HRF
params.snrConds = 1;

% flag for which hemodynamic impulse response 
% function to use if applying a GLM:
% -------------------------------------------
% 0: deconovolve (selective averaging)
% 1: estimate HRF from mean response to all non-null conditions
% 2: Use Boynton et all 1998 gamma function
% 3: Use SPM difference-of-gammas
% 4: Use HRF from Dale and Buckner, 1997 (very similar to Boynton
%    gamma)
% OR, if flag is a char: name of a saved HRF function
%    (stored in subject/HRFs/, where subject is the subject's
%     anatomy directory, where the vAnatomy is stored)
params.glmHRF = 2;                    % boynton hrf
params.glmHRF_params = [3 1.08 2.05]; % good params for Boynton HIRF

% flag for whether or not to estimate temporally-correlated
% noise in data when applying a GLM, referred to as 'whitening':
% (see Dale and Burock, HBM, 2000):
params.glmWhiten = 0;

% # of events per block: this indicates whether each event
% is actually a block of evenly-spaced sub-events (trials).
params.eventsPerBlock = 1; % if block-design, # of events per block

params.ampType = 'betas';

% flag to zero baseline or not
params.normBsl = 1; 

% params.colorOrder = []; % will get from tc_colorOrder, but
%                         % depends on # of conditions specified
%                         % in parfiles.

return