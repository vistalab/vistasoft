function im = fft2c(d)
% Function performs a centered fft2
im = fftshift(fft2(fftshift(d)));