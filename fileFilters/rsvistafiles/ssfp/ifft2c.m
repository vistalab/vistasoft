function im = ifft2c(d)
% Function performs a centered ifft2
im = ifftshift(ifft2(ifftshift(d)));