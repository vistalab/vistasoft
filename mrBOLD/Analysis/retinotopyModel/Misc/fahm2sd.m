function sd=fahm2sd(fahm);
% fwhm2sd - convert full-area-half-maximum to standard deviation
%  sd=fwhm2sd(fwha);

% 08/2006 SOD: wrote it

if nargin < 1,
  help(mfilename);
  return;
end; 

fwhm = sqrt((fahm*4)/pi);

sd = fwhm2sd(fwhm);

