function [count, value] = mrAnatHistogramSmooth(img, nbins, fwhm)
%
% [count, value] = mrAnatHistogramSmooth(img, nbins, fwhm)
%
% Returns a smoothed image histogram.
%
% * nbins should be even (defaults to 256)
% * fwhm is the full-width,half-max of the gaussian smoothing kernel,
% expressed as a proportion of nbins. (defaults to 0.1)
%
% HISTORY:
% 2005.02.05 RFD: wrote it.

if(~exist('nbins','var') | isempty(nbins))
    nbins = 256;
end
if(~exist('fwhm','var') | isempty(fwhm))
    fwhm = 0.1;
end
[count,value] = hist(img(:), nbins);
a = fwhm/2.3548;
x = [-(nbins-1)/2:(nbins-1)/2]/(nbins/2);
g = a*sqrt(2*pi) * exp(-0.5 * (x./a).^2) ./ (sqrt(2*pi) .* a);
count = conv(count, g); 
count = count(nbins/2:end-nbins/2);
return
