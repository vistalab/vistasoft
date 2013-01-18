function im = fftcc(d)
% Function performs a centered 1D IFFT on columns of a matrix

[R C] = size(d);

for c=1:C
    im(:,c) = fftshift(fft(fftshift(d(:,c))));
end