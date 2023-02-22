function newTS = CleanERts(ts, nCycles, nHarms)

% newTS = CleanERts(ts, nCycles, nHarms);
%
% Remove noise from an time-locked event-related time series in the
% frequency domain by interpolating the noise based on non-ER harmonics,
% and subtracting the result from the time series.
%
% Ress, 6/05

% Calculate spectrum and find DC
fts = fftshift(fft(ts));
nFrames = length(ts);
iDC = 1+fix(nFrames/2);

% Remove and save significant harmonics
if ~exist('nHarms', 'var'), nHarms = floor((iDC-2) / nCycles); end
iHarms = iDC + (-nHarms:nHarms)*nCycles;
sigHarms = fts(iHarms);
sigNoise = 0.5 * (fts(iHarms+1) + fts(iHarms-1));
newfts = fts * 0;
cfts = sigHarms - sigNoise;
newfts(iHarms) = cfts;

newTS = real(ifft(fftshift(newfts)));

return