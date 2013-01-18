function im = ifftc(d)
% Function performs a centered ifft
im = ifftshift(ifft(ifftshift(d)));