function [rsmap] = computeTSResStd(view,scanNum,sliceNum,freq)
%
% function [rsmap] = computeTSResStd(view,scanNum,sliceNum,ncycles)
% 
% Computes residual tseries std map removing freq and its harmonics  
% 
%  typical freq=6 cycles/scan
%
% 05/05/99 rmk
% 9/27/99 dbr  Removed hard-coded "72" length.
% djh, 11/00  Calls new version of percentTSeries that has the option of dividing
%             by spatialGradient (estimate of intensity inhomogeneity) instead
%             of dividing by mean at each pixel. Changed input arguments
%             correspondingly.

% Call percentTSeries to load it, and remove dc and trend
view = percentTSeries(view, scanNum, sliceNum);
ptSeries = view.tSeries;
tl=size(ptSeries,1);

% remove only 1f, 2f, 3f, & 5f
freqs=[freq,2*freq,3*freq,5*freq];

% remove all the harmonics
%freqs=[freq:freq:floor(tl/2)-1];

% remove everything but freq+1 and freq-1
%freqs=[1:freq-2,freq,freq+2:floor(tl/2)-1];

nyquistFreq = floor(tl/2)+1;
plusHarmonics=freqs+1;
minusHarmonics=tl-freqs+1;
allFreqs=[plusHarmonics,minusHarmonics];

% Compute fourier transform, zero out freqs, and inverse transform
ft=fft(ptSeries);
ft(allFreqs,:)=0;

% Compute std
rsmap = std(real(ifft(ft)));

% Compensate for the number of zero'd freqs so that this is an estimate of 
% the std of the noise in the time series as if there were no signal modulation.
rsmap = rsmap * sqrt((tl-1)/(tl-length(allFreqs)-1));

% This last step converts it so that it is an estimate of the reliability across
% repeated scans. The reliability of the amplitude estimate depends of course
% on the number of time samples in each scan. For a sinusoid plus noise:
%     std(amps across repeated scans) = std(noise in time series) * sqrt(2/N)
% See simulation in debugging code below.
rsmap = rsmap*sqrt(2/tl);

return

% Debug/test

% Generate simulated data set (1 cyc/scan plus noise)
tl=20; freq = 1;
%tl=30; freq = 2;
t = linspace(0,2*pi,tl+1);
t = t(1:tl)';
sine = sin(freq*t);
ptSeries = repmat(sine,[1,1e4]);
ptSeries = ptSeries + randn(size(ptSeries));

% Compute resStd (code copied from above);
freqs = [freq,2*freq,3*freq,5*freq];
nyquistFreq = floor(tl/2)+1;
plusHarmonics = freqs+1;
minusHarmonics = tl-freqs+1;
allFreqs = [plusHarmonics,minusHarmonics];
ft = fft(ptSeries);
ft(allFreqs,:) = 0;
rsmap = std(real(ifft(ft)));
rsmap = rsmap * sqrt((tl-1)/(tl-length(allFreqs)-1));
rsmap = rsmap * sqrt(2/tl);

% Compute std of amp estimates
ft = fft(ptSeries);
amps = 2*abs(ft(freq+1,:))/tl;

% These two numbers should be the same
mean(rsmap)
std(amps)
