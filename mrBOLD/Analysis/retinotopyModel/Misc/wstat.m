function stats = wstat(v,w,u,ws)
% wstat - weighted statistical measures with correction for upsampling
%
% stats = wstat(data,weights,upsamplefactor,whichstat);
%
% Operations uses all  values of data matrix (data = data(:)).
%
% Weights are directly used, i.e. data with larger associated weight values
% will contribute more to the final statistics. If you want to weight the
% statistics by the standard deviations of the data try:
%  weights = 1./std;
% weights defaults to ones(size(data)), i.e. unweighted - or equally
% weighted - measures.
%
% Incorporates a correction for upsampled data (e.g. V1 in 1x1x1mm3 while
% the actual data was collected at some larger voxel size). The correction
% is based upon the assumption that upsampling duplicates the original
% dataset (upsamplefactor). This is true for nearest-neighbor interpolation
% and roughly true for linear interpolation schemes. If this correction is
% not taken into account the t-values will be overestimated.
% upsamplefactor defaults to 1, i.e. no upsampling.
%
% Outputs structure with mean, standard deviation, standard error, t and p
% value (Ho: mean=0).
%  stats.mean
%  stats.stdev
%  stats.sterr
%  stats.tval
%  stats.pval 
%  stats.df
%
% Optional variable whichstat allows you to specify only one of these
% statistics (useful for scripting, etc).
%
% example for weights:
%   a=linspace(-1,1,100)';
%   w=linspace(0,1,100)';
%     wstat(a)   % unweighted - not significantly different from zero
%     wstat(a,w) %   weighted - significantly different from zero
%
% example for upsampling:
%   a = rand(100,1);
%   b = repmat(a,100,1); % x100 upsampled data
%    wstat(a,[],1)   % no correction for upsampling
%   equals,
%    wstat(b,[],100) % correct for upsampling
%   but not 
%    stat(b)         % no correction for upsampling
%
% 2007/02 SOD: wrote it.

% defaults
if ~exist('v','var') || isempty(v), error('[%s]:Need data',mfilename); end
if ~exist('w','var') || isempty(w), w = ones(size(v)); end % unweighted stats
if ~exist('u','var') || isempty(u), u = 1; end % no upsampling
if ~exist('ws','var'), ws = 'all'; end % all stats

% convert
v = v(:);
w = w(:);

% weighted mean
m = sum(v.*w)./sum(w);

% number of weights larger than 0
n = sum(w>0)./u;

% df
df = (((n-1).*sum(w)./u)./n);
ii = df<0;
if any(ii),
    fprintf(1,'[%s]:degrees of freedom smaller than zero: setting to 0.001.\n',mfilename);
    df(ii) = 0.001;
end;

% weighted standard deviation
s = sqrt( (sum(w.*(v-m).^2)./u) ./ df);

% weighted standard error
se = s./sqrt(sum(w)./u);

% t-test
t = m./sqrt((s.^2)./n);

% two-tailed p test
%p = t2p(t,1,df);

% output
stats.mean  = m;
stats.stdev = s;
stats.sterr = se;
stats.tval  = t;
%stats.pval  = p;
stats.df    = df;

% output
switch lower(ws)
    case {'mean'}
        stats = stats.mean;
    case {'stdev','std','standard deviation'}
        stats = stats.stdev;
    case {'sterr','ste','standard error'}
        stats = stats.sterr;
    case {'t','tval','t value'}
        stats = stats.t;
    case {'df','degrees of freedom'}
        stats = stats.df;
    otherwise
        % do nothing
end

return;
