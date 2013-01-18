function o = mrAnatComputeMutualInfo(im1,im2,sampDensity,xform,cf,fwhm)
% Returns one of various mutual-info type measures of image similarity.
%
% o = mrAnatComputeMutualInfo(im1,im2,sampDensity,xform,cf,fwhm)
%
% NOTE: this code is copied from SPM5's spm_coreg.m! It was a sub-function
% in there, but we needed to call it separately. There are very trivial
% modifications in the calling convention and defaults. See spm_coreg for
% implementation notes and references.
%
% Copyright (C) 2005 Wellcome Department of Imaging Neuroscience
% Written by John Ashburner.
%
% HISTORY:
% 2007.05.01: RFD- extracted code from spm_coreg.


if nargin<6, fwhm = [7 7];   end;
if nargin<5, cf   = 'nmi';    end;
if nargin<4, xform = eye(4);    end;
if nargin<3, sampDensity = [2 2 2];    end;

% Create the joint histogram
H = spm_hist2(im1, im2, xform, sampDensity);

% Smooth the histogram
lim  = ceil(2*fwhm);
krn1 = smoothing_kernel(fwhm(1),-lim(1):lim(1)) ; krn1 = krn1/sum(krn1); H = conv2(H,krn1);
krn2 = smoothing_kernel(fwhm(2),-lim(2):lim(2))'; krn2 = krn2/sum(krn2); H = conv2(H,krn2);

% Compute cost function from histogram
H  = H+eps;
sh = sum(H(:));
H  = H/sh;
s1 = sum(H,1);
s2 = sum(H,2);

switch lower(cf)
	case 'mi',
		% Mutual Information:
		H   = H.*log2(H./(s2*s1));
		mi  = sum(H(:));
		o   = -mi;
	case 'ecc',
		% Entropy Correlation Coefficient of:
		% Maes, Collignon, Vandermeulen, Marchal & Suetens (1997).
		% "Multimodality image registration by maximisation of mutual
		% information". IEEE Transactions on Medical Imaging 16(2):187-198
		H   = H.*log2(H./(s2*s1));
		mi  = sum(H(:));
		ecc = -2*mi/(sum(s1.*log2(s1))+sum(s2.*log2(s2)));
		o   = -ecc;
	case 'nmi',
		% Normalised Mutual Information of:
		% Studholme,  Hill & Hawkes (1998).
		% "A normalized entropy measure of 3-D medical image alignment".
		% in Proc. Medical Imaging 1998, vol. 3338, San Diego, CA, pp. 132-143.
		nmi = (sum(s1.*log2(s1))+sum(s2.*log2(s2)))/sum(sum(H.*log2(H)));
		o   = -nmi;
	case 'ncc',
		% Normalised Cross Correlation
		i     = 1:size(H,1);
		j     = 1:size(H,2);
		m1    = sum(s2.*i');
		m2    = sum(s1.*j);
		sig1  = sqrt(sum(s2.*(i'-m1).^2));
		sig2  = sqrt(sum(s1.*(j -m2).^2));
		[i,j] = ndgrid(i-m1,j-m2);
		ncc   = sum(sum(H.*i.*j))/(sig1*sig2);
		o     = -ncc;
	otherwise,
		error('Invalid cost function specified');
end;

return;

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
%_______________________________________________________________________
