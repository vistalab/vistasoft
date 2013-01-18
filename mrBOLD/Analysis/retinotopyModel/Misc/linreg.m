function [a_fit, sig_a, yy, chisqr, r] = linreg(x,y,sigma)
% linreg - function to perform weighted linear regression (fit a line)
%
% [a_fit, sig_a, yy, chisqr, r] = linreg(x,y,sigma)
%
% Inputs
%   x       Independent variable
%   y       Dependent variable
%   sigma   weight in y [default ones(size(x)), i.e. equal weight]
%           larger associated weight values will contribute more to the 
%           final statistics.
%
% Outputs
%   a_fit   Fit parameters; a(1) is intercept, a(2) is slope
%   sig_a   Estimated error in the parameters a
%   yy      Curve fit to the data
%   chisqr  Chi squared statistic
%   r       Correlation coefficient
%
% 2007/03 SOD: adapted from A. Garcia's Numerical Recipies for Physics
% Matlab toolbox. 

if ~exist('x','var') || isempty(x) || ~exist('y','var') || isempty(y),
  error('[%s]:ERROR:Need x and y values.',mfilename);
end
if ~exist('sigma','var') || isempty(sigma),
  sigma = ones(size(x));
end

%  Evaluate various sigma sums
sigmaTerm = sigma;
s = sum(sigmaTerm);              
sx = sum(x .* sigmaTerm);
sy = sum(y .* sigmaTerm);
sxy = sum(x .* y .* sigmaTerm);
sxx = sum((x .^ 2) .* sigmaTerm);
syy = sum((y .^ 2) .* sigmaTerm);
denom = s*sxx - sx^2;

% Compute intercept a_fit(1) and slope a_fit(2)
a_fit(1) = (sxx*sy - sx*sxy)/denom;
a_fit(2) = (s*sxy - sx*sy)/denom;

% Compute error bars for intercept and slope
sig_a(1) = sqrt(sxx/denom);
sig_a(2) = sqrt(s/denom);

% Evaluate curve fit at each data point and compute Chi^2
yy = a_fit(1)+a_fit(2)*x;     % Curve fit to the data
chisqr = sum( ((y-yy)./sigma).^2 );  % Chi square

% compute weighted correlation coefficient
r  = (sxy-sx.*sy./s)./sqrt((sxx-(sx.^2)./s).*(syy-(sy.^2)./s));

return;
