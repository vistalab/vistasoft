function H = dtiDirTestStatDistr(k, mu1, mu2, N1, N2, n)

% H = dtiDirTestStatDistr(k, mu1, mu2, N1, N2, n)
%
% Generates a Montecarlo estimate of the distribution of the
% Watson test statistic for the difference in mean direction
% between two groups with means mu1 and mu2,
% common concentration k>0 and sample sizes N1 and N2.
% The number of samples used is n.
%
% HISTORY:
%   2004.10.26 ASH (armins@stanford.edu) wrote it.

if (k<=0),
    error('Please provide k > 0');
end

N = N1 + N2;
X1 = dtiDirSample(k, N1*n, mu1);
X2 = dtiDirSample(k, N2*n, mu2);
X = cat(2, reshape(X1, [3 N1 n]), reshape(X2, [3 N2 n]));
X = permute(X, [3 4 5 1 2]);
T = dtiDirTestStat(1:N1, N1+1:N, X);

H = fdrEmpDistr(T, 0.1, 1, [0 max(T)]);
H.hist = H.hist/n;
H.distr = H.distr/n;
nk = 7;
knots = [0:(max(T)/2/nk):max(T)/2,max(T)];
Hs = fdrEmpDensity(H, knots);
%H = Hs;

return