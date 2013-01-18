function [Ybar, S, n, T, df] = symNormalStats(Y, COV_TYPE)

% Mean and covariance of symmetric matrices.
% Covariance structure can be spherical, orthogonally-invariant or full, 
%
%   [Ybar, S, n, T, df] = symNormalStats(Y, COV_TYPE)
%
% Input:
%   Y           Data array of size pxpxnxN, where p is the matrix size,
%                   n is the number of samples, N is arbitrary.
%   COV_TYPE    Type of covariance: 'spherical', 'orth-inv' or 'full' (default).
%
% Output:
%   Ybar        pxpxN array of mean matrices
%   S           qxqxN array of covariance matrices, q=p(p+1)/2
%   n           Number of samples used in the computations.
%   T           Test statistic for testing if covariance is of type COV_TYPE vs. full.
%   df          Asymptotic distribution of T is chi square with this number of degrees of freedom.
%
% E.g.:
%   [Ybar, S, n, T, df] = symNormalStats(Y, 'orth-inv');
%
% Copyright by Armin Schwartzman, 2009

% HISTORY:
%   2009.01.05 ASH (armins@hsph.harvard.edu) wrote it.

% Check inputs
if ~exist('COV_TYPE'), COV_TYPE = 'full'; end
if (~strmatch(COV_TYPE,'spherical') & ~strmatch(COV_TYPE,'orth-inv') & ~strmatch(COV_TYPE,'full')),
    error('Only spherical, rot-inv and full covariance types supported.')
end
if (size(Y,1) ~= size(Y,2)),
    error('Wrong input format');
end

% Constants
sz = size(Y);
p = sz(1);
n = sz(3);
q = p*(p+1)/2;
qq = q*(q+1)/2;

if (n <= qq),
    warning('Not enough subjects to estimate full covariance')
end

% Mean
Ybar = mean(Y,3);

% Covariance
d = vecd(Y - repmat(Ybar,[1 1 n 1])); % qxnxN
Sfull = ndfun('mult', d, permute(d, [2 1 3:ndims(d)]))/(n-1);
detSfull = shiftdim(ndfunm('det',Sfull*(n-1)/n), -1);

switch COV_TYPE,
case 'spherical',
    sigma2 = sum(sum(d.^2, 1), 2)/(q*(n-1));
    S = repmat(sigma2, [q q 1]) .* repmat(eye(q), [1 1 sz(4:end)]);
    T = n*q*log(sigma2*(n-1)/n) - n*log(detSfull);
    df = qq - 1;
case 'orth-inv',
    trc2 = sum(sum(d.^2, 1), 2);
    tr2 = sum(ndfun('mult', [ones(1,p) zeros(1,q-p)], d).^2, 2);
    tau = -(trc2 - (q/p)*tr2)./((q-1)*tr2);
    sigma2 = (trc2 - tau.*tr2)/(q*(n-1));
    c = tau ./ (1 - p*tau);
    S = repmat(eye(q), [1 1 sz(4:end)]);
    S(1:p,1:p,:) = repmat(c, [p p 1]) + repmat(eye(p), [1 1 sz(4:end)]);
    S = repmat(sigma2, [q q 1]) .* S;
    T = n*q*log(sigma2*(n-1)/n) - n*log(1 - p*tau) - n*log(detSfull);
    df = qq - 2;
case 'full',
    S = Sfull;
    T = 0;
    df = 0;
end

% Adjust output
Ybar = permute(Ybar, [1 2 4:ndims(Ybar) 3]);
T = shiftdim(T);

return


%------------------------------------------------------------------------
% Debugging
M = zeros(3);
S = eye(6);
Y = symNormalRnd(M, S, [100 4]);
[Ybar, S, n, T, df] = symNormalStats(Y, 'spherical');
[Ybar, S, n, T, df] = symNormalStats(Y, 'rot-inv');
[Ybar, S, n, T, df] = symNormalStats(Y, 'full');
Ybar(:,:,1), S(:,:,1), n, T, df

