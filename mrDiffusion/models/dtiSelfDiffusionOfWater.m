function D = dtiSelfDiffusionOfWater(temperature, pressure)
%
% D = dtiSelfDiffusionOfWater([temperature=37], [pressure=101.325])
%
% Returns the self-diffusion coefficient of water 
% (in micrometers^2/millisecond) at the given temperature (in
% Centigrade) and pressure (in kPa). (These default to body temp
% and standard atmospheric pressure.)
%
% The function used to compute D is from Krynicki, Green & Sawyer
% (1978). Pressure and temperature dependence of self-diffusion in
% water. Faraday Discuss. Chem. Soc., 66, 199 - 208.
%
% The results also agree pretty well with the values presented in Mills
% (1973). Self-Diffusion in Normal and Heavy Water. JPhysChem 77(5), pg.
% 685 - 688. Mills estimates the self-diffusion of normal water at 35 deg C
% to be 2.919 micrometers^2/ms. This function returns 2.862 at that temp, a
% difference of about 2%. 
% 
% E.g.:
% x=[20:40];figure;plot(x,dtiSelfDiffusionOfWater(x));xlabel('T (C)');ylabel('D (\mum^2/ms)')
%
% See also:
%  http://www.lsbu.ac.uk/water/explan5.html
%
% Note that the relationship between diffusivity and temperature is nearly
% linear over the biologically useful range (e.g. 20-40 deg C) and is very
% well fit by a 3rd order polynomial. Thus, to find t (in Centigrade) given
% d and standard pressure, use: 
%
% p=[0.6056 -6.6855 39.2757 -36.8468]; t = polyval(p,d);
% 
%
% HISTORY:
% 2006.10.06 Bob Dougherty (RFD): Wrote it.

if(~exist('pressure','var')||isempty(pressure))
  P = 101.325;
else
  P = pressure;
end
if(~exist('temperature','var')||isempty(temperature))
  T = 273.15+37;
else
  T = temperature+273.15;
end

% D is in micrometers^2/millisec
% T is in Kelvins (C + 273.15)
% P is in kPa (100 kPa = 1 bar)
D = 12.5 .* exp(P*-5.22*10^-6) .* sqrt(T) .* exp(-925.*exp(P.*-2.6.*10^-6)./(T-(95+P.*2.61.*10^-4)));
return;

fprintf('D = %0.2f micrometers^2/msec (@ %0.1f C & %0.1f kPa).\n',D,T-273.15,P);
