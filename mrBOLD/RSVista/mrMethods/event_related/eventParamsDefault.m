function params = eventParamsDefault;
%
%  params = eventParamsDefault;
%
% Returns default parameters for running
% event-related analyses. Chose them
% to be nice for most KGS-lab block-design
% extps.
%
%
% ras 04/05. 
% ras 08/05 -- Imported into mrVista 2.0

% a signal-processing param -- but useful to have
params.detrend = 1; % just 1 or 0 -- detrend or not

% event-related params
params.stimFiles = {};
params.timeWindow = -8:24;
params.peakPeriod = 4:14;
params.bslPeriod = [-8:0];
params.alpha = 0.05;
params.onsetDelta = 0;
params.snrConds = 1;
params.glmHRF = 1;
params.glmWhiten = 0;
params.normBsl = 1; 

return