function [co, amp, ph] = computeCorAnalSeries(vw, scanNum, sliceNum, nCycles, framesToUse)
%
% [co, amp, ph] = computeCorAnalSeries(vw, scanNum, sliceNum, nCycles, framesToUse)
% 
% Computes correlation analysis for the given scan and slice.  
%
%   nCycles: number of test/control cycles in the scan
%   phaseFlag:  0 use magnitude [default], 1 use phaseTSeries
% 
% djh, 1/22/98
% dbr, 1/28/99  Fixed small bug in selection of positive Fourier
%               components. Previously was ft(1:size(ft, 1)/2) --
%               changed to ft(1:1+fix(size(ft, 1)/2)). This
%               properly deals with odd-length time series.
% dbr, 8/1/00   Added high-pass trend removal and phase analysis options.
% djh, 11/00  Removed detrendFlag from the argument list. percentTSeries
%             chooses the default.
% djh, 11/00  Calls new percentTSeries that has the option of dividing by
%             spatialGradient (estimate of intensity inhomogeneity) instead
%             of dividing by mean at each pixel. Changed input arguments
%             correspondingly.
% djh, 2/2001 Updated to mrLoadRet-3.0
%             Commented out the bit of code that replace's NaNs with zeros
%             because we don't want to confuse a value of zero with a lack of data.
% Ress, 8/02  Added power-spectrum filtering feature requested by Brian W.
%
% ARW , 11/05 Added 'framesToUse' option: subsample the tSeries before
% computing anything on it. Useful if you want to analyze just a portion of
% the time series.


% Call percentTSeries to load it, and remove dc and trend
vw = percentTSeries(vw, scanNum, sliceNum);
ptSeries = viewGet(vw, 'tSeries');

% Rehsape ptSeries into matrix in case it is 3D array
dims = size(ptSeries);
ptSeries = reshape(ptSeries, dims(1), []);

if exist('framesToUse','var')
    ptSeries=ptSeries(framesToUse,:);
end

% Compute Fourier transform
% 
ft = fft(ptSeries);
ft = ft(1:1+fix(size(ft, 1)/2), :);

% This quantity is proportional to the amplitude
%
scaledAmp = abs(ft);

% This is in fact, the correct amplitude
%
amp = 2*(scaledAmp(nCycles+1,:))/size(ptSeries,1);

% We use the scaled amp here which is OK for computing the
% correlation. Note that the noiseBand defines the portion
% of the spectrum to use for the noise metric. As such, this
% calculation now corresponds to the correlation of the fundamental
% stimulus sinusoid with a FILTERED version of the data, where
% noiseBand determines the passband of a square-edged bandpass 
% filter.
%
noiseBand = GetNoiseBand(vw, scanNum);
noiseIndices = CreateNoiseIndices(scaledAmp, nCycles, noiseBand);
sqrtsummagsq = sqrt(sum(scaledAmp(noiseIndices, :).^2));

% (ras 06/07: sometimes sqrtsummagsq can be zero for some voxels;
% don't throw a warning for this line only.)
co = scaledAmp(nCycles+1,:)./sqrtsummagsq;
clear scaledAmp

% Calculate phase:
% 1) add pi/2 so that it is in sine phase.
% 2) minus sign because sin(x-phi) is shifted to the right by phi.
% 3) Add 2pi to any negative values so phases increase from 0 to 2pi.
%
ph = -(pi/2) - angle(ft(nCycles+1,:));
ph(ph<0) = ph(ph<0)+pi*2;

% Reshape into matrices in case we started with 3D arrays
if numel(dims) > 2,
    co  = reshape(co, dims(2), dims(3));
    amp = reshape(amp, dims(2), dims(3));
    ph  = reshape(ph, dims(2), dims(3));
end

