function [alpha,ro] = fit_corr(corr)

kmax = length(corr);

[x eval] = fminsearch(@fit_model, [0, 1/2], optimset('TolX',1e-8),kmax,corr);

alpha = x(1);
ro = x(2);