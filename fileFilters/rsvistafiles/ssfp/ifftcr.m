function im = ifftcr(d)
% Function performs a centered 1D IFFT on rows of a matrix

[R C] = size(d);

for r=1:R
    im(r,:) = ifftshift(ifft(ifftshift(d(r,:))));
end