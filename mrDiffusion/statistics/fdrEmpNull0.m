function [params, paramsCov, fit] = fdrEmpNull0(H, w, DISTR, EST, df)

% [params, paramsCov, fit] = fdrEmpNull0(H, [W], [DISTR], [EST], [DF])
%
% Core function for fdrEmpNull
%
% Estimates parameters of the empirical null distribution belonging
% to the family given by the string DISTR.
% Estimation is done by Poisson regression.
% Allowed distributions are 'norm' (default) and 'chi2'.
% W is a vector of size equal to that of H.x that specifies the weight to be
% given to the values of H.x when fitting the empirical null.
% EST is a list of strings, indicating the parameters to be estimated:
%     {}: none, i.e. only p0 for theoretical null
%     {'mu','s'}: or partial list if DISTR = 'norm'
%     {'a','nu'}: or partial list if DISTR = 'chi2'
%
% If DISTR = 'norm' (default),
% Params is [log(p0), mu, s^2] (or partial list), where
% log(p0) is the log estimate of the proportion that is null.
% mu and s are the mean and std of the fitted normal distribution.
% paramsCov is the covariance matrix of the parameters.
%
% If DISTR = 'chi2',
% Params is [log(p0), a, nu] (or partial list), where
% log(p0) is the log estimate of the proportion that is null.
% a is a scaling factor and nu is the no. of degrees of freedom.
% If EST does not include 'nu', the number nu is fixed to the given value.
% If EST does not include 'a', the scaling factor is fixed at 1.
% paramsCov is the covariance matrix of the parameters.
%
% Example:
%   params = fdrEmpNull(H, W, 'chi2', 3)
%
% fits p0 and a scaling parameter to the chi2 with 3 d.f.
%
% The output fit is a structure with elements:
%   fit.x, the design points of the Poisson regression.
%   fit.X, the design matrix of the Poisson regression.
%   fit.y, the observations of the Poisson regression.
%   fit.yhat, the fitted values of the Poisson regression.
%
% See also:
%       fdrEmpNull
%
% Copyright by Armin Schwartzman, 2006

% HISTORY:
%   2006.11.02 ASH (armins@hsph.harvard.edu) wrote it.

if ~exist('w'),
    w = ones(size(H.x));
else
    w = real(w);
end
if ~exist('DISTR'),
    DISTR = 'norm';
elseif ~strcmp(DISTR, 'norm') & ~strcmp(DISTR, 'chi2'),
    error('Only normal and chi2 distributions supported');
end
if ~exist('EST'),
    EST = '';
end

dx = H.x(2) - H.x(1); % assumes uniformity of bins
y = H.hist;
x = H.x;
N = sum(H.hist);

% Fit parameters
switch DISTR,

case 'norm',
    mu = 0;
    s = 1;

    if ~isempty(strmatch('mu', EST)) & ~isempty(strmatch('s', EST)),
        X = [ones(size(x)), x, x.^2];
        offset = ones(size(x)) * log(N * dx / sqrt(2*pi));
        [b, bdev, bstats] = glmfit(X,y,'poisson','log','off',offset,w,'off');
        s2 = 1/(-2*b(3));
        mu = s2 * b(2);
        logp0 = b(1) + mu^2/(2*s2) + log(s2)/2;
        params = [logp0; mu; s2];
        paramsDeriv = [1, mu, mu^2+s2; 0, s2, 2*mu*s2; 0, 0, 2*s2^2];

    elseif ~isempty(strmatch('mu', EST)) & isempty(strmatch('s', EST)),
        X = [ones(size(x)), x];
        offset = log(N * dx * exp(-x.^2/2) / sqrt(2*pi));
        [b, bdev, bstats] = glmfit(X,y,'poisson','log','off',offset,w,'off');
        mu = b(2);
        logp0 = b(1) + mu^2/2;
        params = [logp0; mu];
        paramsDeriv = [1, mu; 0, s2];

    elseif isempty(strmatch('mu', EST)) & ~isempty(strmatch('s', EST)),
        X = [ones(size(x)), x.^2];
        offset = ones(size(x)) * log(N * dx / sqrt(2*pi));
        [b, bdev, bstats] = glmfit(X,y,'poisson','log','off',offset,w,'off');
        s2 = 1/(-2*b(2));
        logp0 = b(1) + log(s2)/2;
        params = [logp0; s2];
        paramsDeriv = [1, mu^2+s2; 0, 2*s2^2];

    elseif isempty(EST),
        X = ones(size(x));
        offset = log(N*dx/sqrt(2*pi))*ones(size(x)) - x.^2/2;
        [b, bdev, bstats] = glmfit(X,y,'poisson','log','off',offset,w,'off');
        logp0 = b(1);
        params = logp0;
        paramsDeriv = 1;

    else
        error('EST must be {}, ''mu'', ''s'', {''mu'', ''s''}')
    end


case 'chi2',
    nu = df(1);
    a = 1;

    if ~isempty(strmatch('a', EST)) & ~isempty(strmatch('nu', EST)),
        X = [ones(size(x)), x, log(x)];
        offset = ones(size(x)) * log(N * dx);
        [b, bdev, bstats] = glmfit(X,y,'poisson','log','off',offset,w,'off');
        nu = 2*(b(3)+1);
        a = -1/(2*b(2));
        logp0 =  b(1) + log(gamma(nu/2)) + nu/2*log(2*a);
        params = [logp0; a; nu];
        paramsDeriv = [1, a*nu, psi(nu/2) + log(2*a); 0, 2*a^2, 0; 0, 0, 2];

    elseif ~isempty(strmatch('a', EST)) & isempty(strmatch('nu', EST)),
        X = [ones(size(x)), x];
        offset = log(N * dx / gamma(nu/2) * x.^(nu/2-1));
        [b, bdev, bstats] = glmfit(X,y,'poisson','log','off',offset,w,'off');
        a = -1/(2*b(2));
        logp0 = b(1) + nu/2*log(2*a);
        params = [logp0; a];
        paramsDeriv = [1, a*nu; 0, 2*a^2];

    elseif isempty(strmatch('a', EST)) & ~isempty(strmatch('nu', EST)),
        X = [ones(size(x)), log(x)];
        offset = log(N * dx * exp(-x/(2*a)));
        [b, bdev, bstats] = glmfit(X,y,'poisson','log','off',offset,w,'off');
        nu = 2*(b(2)+1);
        p0 = b(1) + log(gamma(nu/2)) + nu/2*log(2*a);
        params = [logp0; nu];
        paramsDeriv = [1, psi(nu/2) + log(2*a); 0, 2];

    elseif isempty(EST),
        X = ones(size(x));
        offset = log(N * dx / gamma(nu/2) * x.^(nu/2-1) / (2*a)^(nu/2)) - x/(2*a);
        [b, bdev, bstats] = glmfit(X,y,'poisson','log','off',offset,w,'off');
        logp0 = b(1);
        params = logp0;
        paramsDeriv = 1;

    else
        error('EST must be {}, ''a'', ''nu'' or {''a'',''nu''}')
    end

end
   
% Output
W = diag(w);
paramsCov = paramsDeriv * inv(X'*W*diag(y)*W*X) * paramsDeriv';

fit.x = x;
fit.X = X;
fit.W = W;
fit.y = y;
fit.yhat = y - bstats.resid;

return


% Debugging
[yhat, dlo, dhi] = glmval(b,X,'log',bstats,0.95,1,offset,'off');
