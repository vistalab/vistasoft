function [fdr,x] = fdrCurve(fit, MODE, sgn)

% [fdr,x] = fdrCurve(fit, [MODE], [sgn])
%
% Computes the false discovery rate curve.
%
% Input:
%   fit     Poisson regression structure from function empNull.
%   MODE    Type of FDR
%               'tail' for tail FDR (default)
%               'local' for local FDR
%   sgn     1 (default) or -1, for right or left tail in 'FDR' case.
%           Irrelevant in 'fdr' case.
%
% Output:
%   fdr     3 column matrix, containing the fdr curve estimate and
%           the upper and lower limits corresponding to the 95% pointwise
%           confidence bands on the empirical distribution of T.
%   x       values at which fdr is evaluated
%
% See also:
%   fdrEmpNull.m

% HISTORY:
%   2006.05.08 ASH (armins@hsph.harvard.edu) wrote it.
%

if ~exist('fit'),
    error('Not enough arguments')
end
if ~exist('MODE'),
    MODE = 'tail';
end
if ~exist('sgn'),
    sgn = 1;
end

[x, X, W, y, yhat] = deal(fit.x, fit.X, fit.W, fit.y, fit.yhat);
K = length(fit.x);

if strcmp(MODE,'tail'),
    S = triu(ones(K,K),1) + diag(ones(1,K))/2;
    if (sgn == -1), S = S'; end
    fdr(:,1) = (S*yhat)./(S*y);
    V = X * inv(X'*W*diag(y)*W*X) * X' * W;
    V = diag(1./(S*yhat)) * S * diag(yhat) * V - diag(1./(S*y));
else % local
    fdr(:,1) = yhat./y;
    V = X * inv(X'*W*diag(y)*W*X) * X' * W - diag(1./y);
end

% Confidence intervals
cov = V * diag(y) * V';
v = diag(cov);
alpha = 0.05;
fdr(:,2) = fdr(:,1) .* exp(norminv(1-alpha/2) * sqrt(v));
fdr(:,3) = fdr(:,1) .* exp(-norminv(1-alpha/2) * sqrt(v));
