function [p]=rmEvaluate2Fits(rss1,rss2,df1,df2,n,units,wtest)
% rmEvaluate2Fits - probability that fit1 == fit2
%
% output = rmEvaluate2Fits(rss1,rss2,df1,df2,n,units,wtest);
%
% Performs f-test and general likelihood ratio (Wilks likelihood)
% tests. Outputs the probability of Ho: data1 == data2.
% Assumes df1>=df2.
%
% rss  : residual sum of squares (model 1 and 2)
% df   : degrees of freedom      (model 1 and 2)
% n    : number of data points
% units: 'p', 'log10p' ['p']        
% wtest: 'ftest','glr'
% 
% 2006/02 SOD: wrote it.

if ieNotDefined('rss1'), error('Need rss1.'); end;
if ieNotDefined('rss2'), error('Need rss2.'); end;
if ieNotDefined('df1'),  error('Need df1.');  end;
if ieNotDefined('df2'),  error('Need df2.');  end;
if ieNotDefined('n'),    error('Need n.');    end;
if ieNotDefined('units'),wtest = 'p';         end;
if ieNotDefined('wtest'),wtest = 'glr';       end;
  
% some sanity checks
if df1 == df2,
  disp(sprintf('[%s]:error: df1 == df2.',mfilename));
  return;
end;
if df1<df2,
  disp(sprintf('[%s]:warning: df1>df2 flipping datasets!',mfilename));
  dftmp = df1;
  df1   = df2;
  df2   = dftmp;
  rsstmp = rss1;
  rss1   = rss2;
  rss2   = rsstmp;
end;

% now do tests
switch lower(wtest),
 case {'f','ftest'}
  % ftest 
  if df1~=df2,
    f = ((rss1-rss2)./rss2) ./ ((df1-df2)./df2);  
    p = 1-fcdf(f,df1-df2,df2);
  else
    f = rss1./rss2;
    p = 1-fcdf(f,df2,df1);
  end;

 case {'g','glr','wilks'}
  % From Fan et al (2001) Generalized likelihood ratio statistics and Wilks
  % phenomenon. The Annals of Statistics. 29(1): 153-193.
  % calculate lambda (glr computation)
  lambda = (n./2).*log(rss1./rss2);
  
  % probability function: Wilks phenomenon lambda approximates
  % chi-squared distribution.
  df = df1-df2;
  p = 1-chi2cdf(lambda,df);
end;

% convert units if requested
switch lower(units),
 case 'log10p',
  sp         = sign(p);
  sp(sp==0)  = 1;
  p          = abs(p);
  p(p<1e-50) = 10^-50; % remove 0
  p          = -log10(p) .* sp;
 case 'p', 
  % do nothing
 otherwise,
  error('[%s]:Unknown unit: %s',mfilename,units);
end;

return;
