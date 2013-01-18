function z=fisherz(r);
% function z=fisherz(r);
%
% transforms r scores (correlations) into fisher z scores by the
% transform r = 0.5*log(1+r)/(1-r);
%
% rmk, 1/14/99

z=0.5*log((1+r)./(1-r));

