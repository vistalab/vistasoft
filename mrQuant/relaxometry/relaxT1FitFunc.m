function err = relaxT1FitFunc(x, m, alpha, tr, te)
%
% function err = relaxT1FitFunc(x, m, alpha, tr, te);
% inputs:
%       x = [r1, pd] where r1 is the inverse of the longitudinal relaxation
%       time (1/T1) and pd is a compsite term representing
%       M_0*G*exp(-TE/T_2star) 
%       m: spgr data 
%
%       alpha: flip angle (in degrees)
%       tr, te = tr and te
%
%   Output: the error for each measurement
%
%

r1 = x(1);
pd = x(2);

%pd = M_0*G*exp(-te/T_2star);
S_alpha = pd .* sin(alpha) .* (1-exp(-r1.*tr)) ./ (1-cos(alpha) .* exp(-r1.*tr));
err = S_alpha - m;

return;
