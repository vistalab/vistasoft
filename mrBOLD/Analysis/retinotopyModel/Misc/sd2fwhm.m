function [fwhm, equivRFSize ] = sd2fwhm(sd)
%PRF standard deviation to full-width-half-maximum of pRF and equivalent neural rf size 
%
%    [fwhm, equivRFSize ] = sd2fwhm(sd)
%
%   The pRF model is exp(- (d^2)/(2 sigma^2))
%   This function reaches a peak of 1.  At half maximum we have
%   
%     (1/2) = exp(- (d^2)/(2 sigma^2)), solving we have
%     d = sigma * sqrt(2 ln (2))
%
%   For the full width, rather than the half width, we must multiply d by 2
%   so that the final formula is as below
%
%       fwhm = 2 * sigma * sqrt(2 ln (2))
%
%   The area of the pRF is pi*(fwhm/2)^2 (pi r^2)
%   If we want the equivalent rf size, we want the square root of this area
%   equivRFSize = sqrt(pi*(fwhm/2)^2)
%
%   This also simplifies to equivRFSize = sigma * sqrt(pi * 2 * ln(2))
%
%
% Example:
%    sd = 7;   % Example sd of a pRF for TO-1
%    [fwhm, equivSize] = sd2fwhm(sd)
%
% 10/2005 SOD: wrote it

if nargin < 1,
  help(mfilename);
  return;
end;

fwhm = sd.*(2*sqrt(2*log(2)));

if nargout > 1
    equivRFSize = sqrt(pi*(fwhm/2)^2);
end

return;


