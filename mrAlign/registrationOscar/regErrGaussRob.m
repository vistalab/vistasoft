function e = regErrGaussRob(P, x, hx);
% regErrGaussRob - robust error measure between a histogram and a weighted
%                  sum of two Gaussian function
%
% regErrGaussRob(P, x, hx);
%
% INPUT:
% - P: parameters of the two Gaussians
%  p(1)->mean1, p(2)->var1, p(3)->mean2, p(4)->var2, p(5) and p(6) -> weights
% - x  - values where the histogram is sampled
% - hx - normalized histogram
%
% Oscar Nestares - 5/99
%

% Gaussian pdf's at x
p1 = regPgauss1d(x,P(1),P(2));
p2 = regPgauss1d(x,P(3),P(4));

% weighted sum
p = (P(5)*p1+P(6)*p2)/(P(5)+P(6));

% robust error measure between the Gausian PDF and the histogram
% (p-hx) should be normalized by a constnat alpha. For this problem,
% alpha = 1 works fine.
e = sum(-1./(1+((p-hx)).^2));

%plot(x,p,'-',x,hx,'--'); drawnow
