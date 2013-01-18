function p = regPgauss1d(x,mu,sigma2);
% regPgauss1d - 1D Gaussian pdf (probability density function)
%
%

p = 1/sqrt(2*pi*sigma2) * exp(-(1/2)*(x-mu).^2 / sigma2);
