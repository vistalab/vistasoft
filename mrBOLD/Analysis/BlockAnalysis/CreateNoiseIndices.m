function noiseIndices = CreateNoiseIndices(amps, nCycles, noiseBand)

% noiseIndices = CreateNoiseIndices(amps, nCycles);
%
% Creates noise indices corresponding to the present setting of
% the noiseBand field in dataTYPES.blockedAnalysisParams. The
% noiseBand input has the following forms:
%
% 0                Default behavior -- use entire power spectrum
% non-zero scalar  Bandpass filter the power spectrum around the
%                  signal frequency, using this value as half-width
% vector           Filter explicitly using given values. Spectral values
%                  are assumed to be zero at the signal frequency. For
%                  example, the vector [-5 -4 -3 -2 -1 0 1 2] would bandpass
%                  the values starting 5 frequency samples below the signal
%                  through 2 samples above the signal.
%    JL add 11/04  If vector is purely imaginary, then the number it
%                  indicates is what you take away from the full noise Band.
%                  Example: the vector [0 5 10]*sqrt(-1) means noiseIndices
%                  is 1:size(amps,1) but without [0 5 10]+nCycles frequencies.
%
% Ress, 8/02

nAmps = size(amps, 1);
if length(noiseBand) > 1
    if isreal(noiseBand);
        noiseIndices = 1 + nCycles + noiseBand;
    else
        noiseIndices = setdiff(1:nAmps, imag(noiseBand) + nCycles + 1);
    end
elseif noiseBand == 0
  noiseIndices = 1:nAmps;
else
  nB = fix(noiseBand/2);
  noiseIndices = 1 + nCycles + (-nB:nB);
end

noiseIndices = noiseIndices((noiseIndices <= nAmps) & (noiseIndices > 0));
