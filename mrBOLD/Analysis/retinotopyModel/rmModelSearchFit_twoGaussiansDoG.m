function e = rmModelSearchFit_twoGaussiansDoG(p,Y,Xv,Yv,stim,t)
% rmModelSearchFit_twoGaussians - actual fit function of rmSearchFit
%
% error = rmModelSearchFit_twoGaussians(p,Y,trends,Gx,Gy,stim,rawrss);
%
% Basic barebones fit of a single time-series. Error is returned in
% percentage: 100% is RSS of unfitted time-series. This way we can quantify
% the improvement of the fit independend of the variation in the raw
% time-series.
%
% 2006/06 SOD: wrote it.
% 2006/12 SOD: modifications for fmincon, this is litterally called >>10000
% times so we cut every corner possible. 


% make RF (taken from rfGaussian2d)
Xv = Xv - p(1);   % positive x0 moves center right
Yv = Yv - p(2);   % positive y0 moves center up
RF = zeros(numel(Xv),2);
RF(:,1) = exp( (Yv.*Yv + Xv.*Xv) ./ (-2.*(p(3).^2)) );
RF(:,2) = exp( (Yv.*Yv + Xv.*Xv) ./ (-2.*(p(4).^2)) );


% make prediction (taken from rfMakePrediction)
X = [stim * RF t];

% fit
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

% force positive fit
b(1) = abs(b(1));

%force negative b2 fit
b(2) = -(abs(b(2)));

% The center of the pRF should be positive. Thus, b(1)+b(2)>=0, or 
% b(2) should be larger than -b(1) (implemented).
b(2) = max(b(2),-b(1));

% force second Gaussian to be negative
b(2) = -abs(b(2));

% compute residual sum of squares (e)
e = norm(Y - X*b);

return;
