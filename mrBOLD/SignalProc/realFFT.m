function [ft x] = realFFT(tSeries);
% Return just the real, positive part of the FFT of a time series, sans
% the DC component.
%
% [ft x] = realFFT(tSeries);
%
% This code replicates a small set of operations which is repeatedly
% performed in corAnal and related analysis code. It appears in 
% plotMeanFFTSeries, among other places.
%
% ras, 07/2007.  Thought it'd be useful to have a separate spectrum
% for this function. 

% we allow 2-D or 1-D vectors. For 1-D vectors, ensure it's a column
% vector:
if size(tSeries, 1)==1, tSeries = tSeries';		end

nFrames = size(tSeries, 1);
maxCycles = round(nFrames / 2);
absFFT  = 2 * abs( fft(tSeries) ) / nFrames;
ft = absFFT(2:maxCycles+1,:);

% return sampling frequencies, if they're requested:
if nargout > 1
	x = 1:nCycles;
end

return