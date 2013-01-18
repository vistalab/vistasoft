function ftSeries = FilterF(freqRange, tSeries, cutoff)

% ftSeries = FilterF(freqRange, tSeries, cutoff);
%
% Perform a bandpass filtering of input time series.
%
% INPUTS
%  freqRange   A two-element vector giving the low and high
%              frequency band limits of the filter as fractions
%              of the Nyquist frequency. If only one value is 
%              given, a low-pass filter is implemented. If either
%              value is negative, than the range is interpreted
%              as the stopband to allow implementation of notch
%              and high-pass filters.
%  tSeries     The time series to be filtered.
%  cutoff      The sharpness of the cutoff edge expressed as a
%              fraction of the bandwidth. Defaults to 3*delta-freq.
%
% OUTPUT
%  ftSeries    The filtered time series.
%
% DBR  5/99

% Check and adjust frequency-range input
if length(freqRange) == 0
  ftSeries = tSeries;
  return
end
if length(freqRange) == 1
  % Make lowpass filter
  freqRange = [0 freqRange];
end
% Check for stopband filtering:
if ~all(freqRange >= 0)
  stopFlag = 1;
  freqRange = abs(freqRange);
else
  stopFlag = 0;
end

% Set cutoff value if not given:
if ~exist('cutoff', 'var'), cutoff = 0.10; end

% Build frequency series
nT = length(tSeries);
dFreq = 2 / nT;
fMin = -floor(nT/2) * dFreq;
fMax = fMin + (nT - 1)*dFreq;
freq = linspace(fMin, fMax, nT)';


% Create and smooth filter function
fSeries = abs(freq) <= freqRange(2) & abs(freq) >= freqRange(1);
n1 = round(cutoff/4 * diff(freqRange)/dFreq);
if n1 < 1, n1 = 1; end
nSmooth = 1 + 2*n1;
nIter = 3;
if nSmooth > 1
  kernel = repmat(1/nSmooth, 1, nSmooth);
  for iSmooth=1:nIter
    fSeries = conv(kernel, fSeries);
    fSeries = fSeries(1+n1:nT+n1);
  end
end

% Invert filter, if specified:
if stopFlag, fSeries = 1 - fSeries; end

% Apply filter in FT domain:
fSeries = repmat(fSeries', [size(tSeries, 1) 1]);
ftSeries = real(ifft(fft(tSeries) .* fftshift(fSeries)));
