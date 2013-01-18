function empNull = fdrEmpNull(T, DISTR, dt, EST, df, lims)

% empNull = fdrEmpNull(T, DISTR, dt, EST, [df], [lims])
%
% Estimates empirical null by Poisson regression based on a histogram of
% the given test statistics.
%
% Input:
%   T        Vector of test statistics
%   DISTR    Theoretical null distribution: 'norm' (default) and 'chi2'.
%   dt       Histogram bin width
%   EST      List of strings, indicating the parameters to be estimated:
%                {}: none, i.e. only p0 for theoretical null
%                {'mu','s'}: or partial list if DISTR = 'norm'
%                {'a','nu'}: or partial list if DISTR = 'chi2'
%   df       Specific degrees of freedom for theoretical null
%            if DISTR = 'chi2'. Irrelevant if DISTR = 'norm'.
%   lims     Limits for the Poisson regression. Defaults are
%                percentile(T, [10 90]) if DISTR = 'norm'
%                percentile(T, 90) if DISTR = 'chi2'
%
% Output:
%   empNull  Structure with fields:
%                par    names of parameters:
%                           {'p0','mu','s'} if DISTR = 'norm'
%                           {'p0','a','nu'} if DISTR = 'chi2'
%                est    point estimates of the above parameters
%                conf   95% confidence intervals for the above parameters
%                H      Histogram of T. Structure with fields:
%                           x      bin centers
%                           hist   histogram counts
%                H0     Histogram of empirical null. Structure with fields:
%                           x      bin centers
%                           hist   histogram counts
%                lims   The limits used for the Poisson regression
%                fit    Structure with details of the Poisson regression
%                           x      design points of the Poisson regression
%                           X      design matrix of the Poisson regression
%                           y      observations of the Poisson regression
%                           yhat   fitted values of the Poisson regression
%
% See also:
%       fdrEmpNull0, fdrHist, fdrCurve
%
% Copyright by Armin Schwartzman, 2006

% HISTORY:
%   2006.11.08 ASH (armins@hsph.harvard.edu) wrote it.

if ~exist('EST'),
    EST = '';
end
if ~exist('lims') || isempty('lims'),
    switch(DISTR),
    case 'norm',
        lims = prctile(T, [10 90]);
    case 'chi2',
        lims = prctile(T, 90);
    end
end
if ~exist('df'),
    df = 1;
end


confLevel = 0.05;
conf = norminv(1 - confLevel/2);

switch(DISTR),
case 'norm',
    H = fdrHist(T,dt);
    w = (H.x > lims(1)) & (H.x < lims(2));
    [params, paramsCov, fit] = fdrEmpNull0(H, w, DISTR, EST, df);
    paramsConf = [params - conf*sqrt(diag(paramsCov)), params + conf*sqrt(diag(paramsCov))];
    names = {'p0','mu','s'};
    mu = 0;
    s = 1;
    if ~isempty(strmatch('mu', EST)) & ~isempty(strmatch('s', EST)),
        params = [exp(params(1)); params(2); sqrt(params(3))];
        paramsConf = [exp(paramsConf(1,:)); paramsConf(2,:); sqrt(paramsConf(3,:))];
    elseif ~isempty(strmatch('mu', EST)) & isempty(strmatch('s', EST)),
        params = [exp(params(1)); params(2); s];
        paramsConf = [exp(paramsConf(1,:)); paramsConf(2,:); s, s];
    elseif isempty(strmatch('mu', EST)) & ~isempty(strmatch('s', EST)),
        params = [exp(params(1)); mu; sqrt(params(2))];
        paramsConf = [exp(paramsConf(1,:)); mu, mu; sqrt(paramsConf(2,:))];
    elseif isempty(EST),
        params = [exp(params(1)); mu; s];
        paramsConf = [exp(paramsConf(1,:)); mu, mu; s, s];
    else
        error('EST must be {}, ''mu'', ''s'', {''mu'', ''s''}')
    end

case 'chi2',
    H = fdrHist(T,dt,1);
    lims = prctile(T,90);
    w = (H.x < lims(1));
    [params, paramsCov, fit] = fdrEmpNull0(H, w, DISTR, EST, df);
    paramsConf = [params - conf*sqrt(diag(paramsCov)), params + conf*sqrt(diag(paramsCov))];
    names = {'p0','a','nu'};
    nu = df(1);
    a = 1;
    if ~isempty(strmatch('a', EST)) & ~isempty(strmatch('nu', EST)),
        params = [exp(params(1)); params(2); params(3)];
        paramsConf = [exp(paramsConf(1,:)); paramsConf(2,:); paramsConf(3,:)];
    elseif ~isempty(strmatch('a', EST)) & isempty(strmatch('nu', EST)),
        params = [exp(params(1)); params(2); nu];
        paramsConf = [exp(paramsConf(1,:)); paramsConf(2,:); nu, nu];
    elseif isempty(strmatch('a', EST)) & ~isempty(strmatch('nu', EST)),
        params = [exp(params(1)); a; params(2)];
        paramsConf = [exp(paramsConf(1,:)); a, a; paramsConf(2,:)];
    elseif isempty(EST),
        params = [exp(params(1)); a; nu];
        paramsConf = [exp(paramsConf(1,:)); a, a; nu, nu];
    else
        error('EST must be {}, ''a'', ''nu'' or {''a'',''nu''}')
    end

end

% Output
H0.x = H.x;
H0.hist = fit.yhat;
empNull = struct('par', {names}, 'est', params, 'conf', paramsConf, 'H', H, 'H0', H0, 'lims', lims, 'fit', fit);










