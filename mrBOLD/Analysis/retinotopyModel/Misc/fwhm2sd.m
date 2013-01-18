function sd=fwhm2sd(fwhm);
% fwhm2sd - convert full-width-half-maximum to standard deviation
%  sd=fwhm2sd(fwhm);

% 10/2005 SOD: wrote it

if nargin < 1,
  help(mfilename);
  return;
end;

sd = fwhm./(2*sqrt(2*log(2)));

