function inp = regCorrMeanInt(inp);
% regCorrMeanInt - Detects and Corrects for oscillation in the mean intensity
%                  of the inplanes, often caused by having the INTERLEAVE
%                  button OFF when acquiring the anatomy inplanes.
%                  Detection: based on the energy of the 1/2 cycle/sample
%                             harmonic of the mean signal.
%                  Correction: adjusts the mean intensity of the odd
%                  inplanes to a 2nd order polynomial, and then scales
%                  the even inplanes to match the values predicted by the
%                  polynomial.
%
%    inp = regCorrMeanInt(inp);
%
% Oscar Nestares - 5/99
%

% mean intensity of the inplanes
m = squeeze(mean(mean(inp)));

% FFT of the mean signal (using the next closest power of two)
L = length(m);
N = 2^ceil(log(L)/log(2));
M = abs(fft(m, N));

% oscillation if last harmonic greater than the mean of the other harmonics
if mean(M(2:N/2)) < M(N/2+1)
   disp('Mean intensities of the inplanes are oscillating.')
   disp('Was INTERLEAVE button ON?')
   disp('Correcting oscillation and continuing...')

   % fiting a 2nd order polynomial to the odd samples
   x = [1:length(m)]';
   po = polyfit(x(1:2:L),m(1:2:L),2);
   mo = polyval(po,x);

   % re-scaling the even samples 
   for k=2:2:L
      inp(:,:,k) = inp(:,:,k) * mo(k)/m(k);
   end
end


