function [co, amp, ph] = computeCorAnalTSeries(vw, scan, tSeries)

% Variable check
%
if notDefined('vw'),        vw = getCurView;                    end
if notDefined('scan'),      scan = viewGet(vw, 'curscan');      end

% Compute Fourier transform
% 
ft = fft(tSeries);
ft = ft(1:1+fix(size(ft, 1)/2), :);

% This quantity is proportional to the amplitude
%
scaledAmp = abs(ft);

% This is in fact, the correct amplitude
%
nCycles = viewGet(vw, 'nCycles', scan);
amp = 2*(scaledAmp(nCycles+1,:))/size(tSeries,1);

% We use the scaled amp here which is OK for computing the
% correlation. Note that the noiseBand defines the portion
% of the spectrum to use for the noise metric. As such, this
% calculation now corresponds to the correlation of the fundamental
% stimulus sinusoid with a FILTERED version of the data, where
% noiseBand determines the passband of a square-edged bandpass 
% filter.
%
noiseBand    = GetNoiseBand(vw, scan);
noiseIndices = CreateNoiseIndices(scaledAmp, nCycles, noiseBand);
sqrtsummagsq = sqrt(sum(scaledAmp(noiseIndices, :).^2));

% (ras 06/07: sometimes sqrtsummagsq can be zero for some voxels;
% don't throw a warning for this line only.)
warning off MATLAB:divideByZero
co = scaledAmp(nCycles+1,:)./sqrtsummagsq;
warning on MATLAB:divideByZero
clear scaledAmp

% Calculate phase:
% 1) add pi/2 so that it is in sine phase.
% 2) minus sign because sin(x-phi) is shifted to the right by phi.
% 3) Add 2pi to any negative values so phases increase from 0 to 2pi.
%
ph = -(pi/2) - angle(ft(nCycles+1,:));
ph(ph<0) = ph(ph<0)+pi*2;
