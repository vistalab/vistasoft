function im = fftcr(d)
% Function performs a centered 1D IFFT on columns of a matrix

[R C] = size(d);

for r=1:R
    im(r,:) = fftshift(fft(fftshift(d(r,:))));
end