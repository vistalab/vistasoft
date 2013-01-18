function im = fftc(d)
% Function performs a centered fft
im = fftshift(fft(fftshift(d)));