function [t, stats] = upsampledttest(x,ufac,w);
% upsampledttest - t test for upsampled data
%
% [t, stat_struct] = upsampledttest(x,upsamplefactor,weight)
%
% T test for upsampled data (e.g. V1 in 1x1x1mm3 while the actual data was
% collected at some larger voxel size). The correction is based upon the
% assumption that upsampling duplicates the original dataset
% (upsamplefactor). This is true for nearest-neighbor interpolation and 
% roughly true for linear interpolation schemes. If this correction is not 
% taken into account the t-values will be overestimated.
% Option to specify weight for each value.
% 
% example:
%   a = rand(100,1);
%   b = a*ones(1,100);b=b(:);
%    upsampledttest(a,1)
%   equals,
%    upsampledttest(b,100)
%
% 2006/06/01 SOD: wrote it.

if nargin < 2 || isempty(ufac),
  ufac = 1;
end;

if size(x,1) == 1, x = x(:); end;

% mean and n
xmean = mean(x);
n     = size(x,1);

% define corrected df
stats.df    = n./ufac-1;
% this could go below 0
if stats.df < 0,
    disp(sprintf(['[%s]:WARNING:corrected df < 0, setting to something ' ...
                  'small. Use data with caution.'],mfilename));
    stats.df  = 0.00001;
end;

% variance corrected for upsampling
xvar  = ( sum((x-xmean).^2) ./ufac) ./ stats.df;

% t (df corrected for upsampling)
t     = xmean ./ sqrt(xvar ./ (n./ufac));

% compute more stats if requested
if nargout > 1,
  stats.t     = t;
  stats.mean  = xmean;
  stats.stdev = sqrt(xvar);
  stats.sterr = sqrt(xvar)./sqrt(n./ufac);
  stats.p     = 0.5*betainc(stats.df./(stats.df+t.^2),stats.df/2,0.5);
end;

return;
