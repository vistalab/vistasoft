function test_detrendTSeries
%Validate calculation to detrend BOLD time series
%
%   test_detrendTSeries()
% 
% Tests: detrendTSeries
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example:  test_detrendTSeries()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2012


% This is the validation file
val = mrtGetValididationData('detrendedTSeries');

% we stored a time series in the validation file
ts = val.ts;

% detrend three ways
[ts1, fit1] = detrendTSeries(ts,-1);        % linear
[ts2, fit2] = detrendTSeries(ts, 2);        % quadratic
[ts3, fit3] = detrendTSeries(ts, 1, 20);    % high pass

% These are the items we stored in the validation file
%
% val.ts1   = [mean(ts1)  std(ts1)  median(ts1)];
% val.fit1  = [mean(fit1) std(fit1) median(fit1)];
% val.ts2   = [mean(ts2)  std(ts2)  median(ts2)];
% val.fit2  = [mean(fit2) std(fit2) median(fit2)];
% val.ts3   = [mean(ts3)  std(ts3)  median(ts3)];
% val.fit3  = [mean(fit3) std(fit3) median(fit3)];
%
%
% save(vFile, '-struct', 'val')
%
% Note: this is how the random numbers for the time series were generated:
%
% % Seed random stream. This will be used to generate a simulated tseries.
% s = RandStream('mt19937ar','Seed',1);
% RandStream.setGlobalStream(s);
%
% % Generate a time series (300 points, with some smoothing)
% val.ts = single(imblur(randn(300,1), 5));


% Test that each way of detrending gives the expected answers
assertElementsAlmostEqual(val.ts1, [mean(ts1)  std(ts1)  median(ts1)], 'relative');
assertElementsAlmostEqual(val.ts2, [mean(ts2)  std(ts2)  median(ts2)], 'relative');
assertElementsAlmostEqual(val.ts3, [mean(ts3)  std(ts3)  median(ts3)], 'relative');

assertVectorsAlmostEqual(val.fit1, [mean(fit1) std(fit1) median(fit1)], 'relative');
assertVectorsAlmostEqual(val.fit2, [mean(fit2) std(fit2) median(fit2)], 'relative');
assertVectorsAlmostEqual(val.fit3, [mean(fit3) std(fit3) median(fit3)], 'relative');

mrvCleanWorkspace;
