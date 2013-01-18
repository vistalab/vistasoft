function outIm = mrAnatSmoothUint8(im,fwhm)
% SPM code to convolve a uint8 volume with a smoothing kernel (fwhm in voxels).
%
% outIm = mrAnatSmoothUint8(im,fwhm)
%
% NOTE: this code is copied straight from SPM5's spm_coreg.m! It was a
% sub-function in there, but we needed to call it separately. 
%
% Copyright (C) 2005 Wellcome Department of Imaging Neuroscience
% Written by John Ashburner.
%
% HISTORY:
% 2007.05.03: RFD- extracted code from spm_coreg.

if(length(fwhm)==1) fwhm = repmat(fwhm,1,3); end

lim = ceil(2*fwhm);
x  = -lim(1):lim(1); x = smoothing_kernel(fwhm(1),x); x  = x/sum(x);
y  = -lim(2):lim(2); y = smoothing_kernel(fwhm(2),y); y  = y/sum(y);
z  = -lim(3):lim(3); z = smoothing_kernel(fwhm(3),z); z  = z/sum(z);
i  = (length(x) - 1)/2;
j  = (length(y) - 1)/2;
k  = (length(z) - 1)/2;
outIm = zeros(size(im),'uint8');
spm_conv_vol(im,outIm,x,y,z,-[i j k]);
return;
%_______________________________________________________________________

%_______________________________________________________________________
function krn = smoothing_kernel(fwhm,x)

% Variance from FWHM
s = (fwhm/sqrt(8*log(2)))^2+eps;

% The simple way to do it. Not good for small FWHM
% krn = (1/sqrt(2*pi*s))*exp(-(x.^2)/(2*s));

% For smoothing images, one should really convolve a Gaussian
% with a sinc function.  For smoothing histograms, the
% kernel should be a Gaussian convolved with the histogram
% basis function used. This function returns a Gaussian
% convolved with a triangular (1st degree B-spline) basis
% function.

% Gaussian convolved with 0th degree B-spline
% int(exp(-((x+t))^2/(2*s))/sqrt(2*pi*s),t= -0.5..0.5)
% w1  = 1/sqrt(2*s);
% krn = 0.5*(erf(w1*(x+0.5))-erf(w1*(x-0.5)));

% Gaussian convolved with 1st degree B-spline
%  int((1-t)*exp(-((x+t))^2/(2*s))/sqrt(2*pi*s),t= 0..1)
% +int((t+1)*exp(-((x+t))^2/(2*s))/sqrt(2*pi*s),t=-1..0)
w1  =  0.5*sqrt(2/s);
w2  = -0.5/s;
w3  = sqrt(s/2/pi);
krn = 0.5*(erf(w1*(x+1)).*(x+1) + erf(w1*(x-1)).*(x-1) - 2*erf(w1*x   ).* x)...
      +w3*(exp(w2*(x+1).^2)     + exp(w2*(x-1).^2)     - 2*exp(w2*x.^2));

krn(krn<0) = 0;
return;