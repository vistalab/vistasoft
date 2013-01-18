function e = rmModelSearchFit_oneGaussianUnsigned(p,Y,Xv,Yv,stim,t)
% rmModelSearchFit_oneGaussianUnsigned - actual fit function of rmSearchFit
%
% error = rmModelSearchFit(p,Y,trends,Xgrid,YGrid,stimulusMatrix);
%
% Basic barebones fit of a single time-series. Error is returned in
% percentage: 100% is RSS of unfitted time-series. This way we can quantify
% the improvement of the fit independend of the variation in the raw
% time-series.
%
% 2006/06 SOD: wrote it.
% 2006/12 SOD: modifications for fmincon, this is litterally called >10000
% times so we cut every corner possible. 

% make RF (taken from rfGaussian2d)
Xv = Xv - p(1);   % positive x0 moves center right
Yv = Yv - p(2);   % positive y0 moves center up
RF = exp( (Yv.*Yv + Xv.*Xv) ./ (-2.*(p(3).^2)) );

% make prediction (taken from rfMakePrediction)
X = [stim*RF t];

% fit - inlining pinv
%b = pinv(X)*Y; 
[U,S,V] = svd(X,0);
s = diag(S); 
tol = numel(X) * eps(max(s));
r = sum(s > tol);
if (r == 0)
    pinvX = zeros(size(X'));
else
    s = diag(ones(r,1)./s(1:r));
    pinvX = V(:,1:r)*s*U(:,1:r)';
end
b = pinvX*Y;

% compute residual sum of squares (e)
e = norm(Y - X*b);
return;
