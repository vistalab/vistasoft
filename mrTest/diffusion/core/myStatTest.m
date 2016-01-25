function [p, s, df] = myStatTest(x1, x2, type)
% [p, s, df] = myStatTest(X1, X2, 'test') 
% Statistical test of two samples- gives the confidence level for
% different tests of the two samples X1 and X2.
%
%       'test'   Null hypothesis      Assumption on distributions  Type
%       -----------------------------------------------------------------
%         't'    Means are equal      The variances are equal      t-test
%         'u'    Means are equal      The variances are not equal  t-test
%         'p'    Means are equal      The data are paired          t-test
%         'f'    Variances are equal                               F-test
%         'r'    Pearson Correlation                               Z-test
%        
%       TEST(X1, X2) performs a t-test (for equal variances) by default.
%
%       [P S] = TEST(X1, X2, ['test']) returns the confidence level in P
%       and the value of the statistic (t or F) in S.
%
%       Ref: Press et al. 1992. Numerical recipes in C. 14.2, Cambridge.
%
if (nargin == 2)
   type = 't' ;
end
nanInds1 = isnan(x1);
nanInds2 = isnan(x2);
  
if (type == 't')
  [p s df] = ttest(x1(~nanInds1), x2(~nanInds2)) ;
elseif (type == 'u')
  [p s df] = uttest(x1(~nanInds1), x2(~nanInds2)) ;
elseif (type == 'p')
  nanIndsBoth = nanInds1|nanInds2;
  [p s df] = pttest(x1(~nanIndsBoth), x2(~nanIndsBoth)) ;
elseif (type == 'f')
  [p s] = ftest(x1(~nanInds1), x2(~nanInds2)) ;
elseif (type == 'r')
  sz = max([size(x1);size(x2)]);
  for(k=1:sz(1))
    nanIndsBoth(k,:) = nanInds1(k,:)|nanInds2(k,:);
  end
  n = sum(~nanIndsBoth,1);
  df = n-2;
  if(sz(1)>1&&sz(2)>1)
    % vectorized version- assumes that x1 is Nx1 and x2 is NxM. Returns the
    % 1xM correlation coefficients.
    mn = mean(x1,1);
    sd = std(x1,0,1);
    Z1 = (x1-repmat(mn, [sz(1) 1])) ./ repmat(sd, [sz(1) 1]);
    mn = mean(x2,1);
    sd = std(x2,0,1);
    Z2 = (x2-repmat(mn, [sz(1) 1])) ./ repmat(sd, [sz(1) 1]);
    s = 0;
    for(k=1:sz(1))
        s = s + Z1(k,:).*Z2(k,:);
    end
    s = s./n;
    fZ = 0.5*(log((1+s)./(1-s)));
    p = erfc((abs(fZ).*sqrt(df))./sqrt(2));
  else
    % just use matlab's built-in
    [pearson,p] = corrcoef(x1(~nanIndsBoth), x2(~nanIndsBoth));
    s = pearson(1,2);
    p = p(1,2);
    %     t = s/sqrt((1-s^2)/df);
    %     p = betainc( df / (df + t*t), df/2, 0.5);
    % Fischer's z' method (slightly less conservative):
    %z = 0.5*(log((1+s)/(1-s)));
    %df = length(x1)-3;
    %p = erfc((abs(z)*sqrt(df))/sqrt(2));
  end
elseif(type=='k')
  % Kendall's tau
  % This is essentially a vectorized, simplfied version of the
  % implementation in Matlab's 'corr' function.
  sz = max([size(x1);size(x2)]);
  for(k=1:sz(1))
    nanIndsBoth(k,:) = nanInds1(k,:)|nanInds2(k,:);
  end
  n = sum(~nanIndsBoth,1);
  n2const = n.*(n-1)./2;
  [x1Rank,x1Adj] = tiedrank(x1,1);
  [x2Rank,x2Adj] = tiedrank(x2,1);
  K = zeros(1,sz(2));
  for(k=1:sz(1)-1)
    sgn1 = sign(repmat(x1(k,:),sz(1)-k,1)-x1(k+1:sz(1),:));
    % Zero-out Nans to effectively ignore these data points (the
    % missing values are accounted for in the DF)
    sgn1(isnan(sgn1)) = 0;
    sgn2 = sign(repmat(x2(k,:),sz(1)-k,1)-x2(k+1:sz(1),:));
    sgn2(isnan(sgn2)) = 0;
    for(j=1:size(sgn1,1))
      K = K + sgn1(j,:).*sgn2(j,:);
    end
  end
  %for(k=1:sz(1)-1)
  %  tmp = sum(sign(repmat(x1(k,:),sz(1)-k,1)-x1(k+1:sz(1),:)).*sign(repmat(x2(k,:),sz(1)-k,1)-x2(k+1:sz(1),:)),1);
  %  tmp(nanIndsBoth(k,:)) = 0;
  %  K = K + tmp;
  %end
  s = K ./ sqrt((n2const - x1Adj(1,:)).*(n2const - x2Adj(1,:)));
  ties = ((x1Adj(1,:)>0) | (x2Adj(1,:)>0));
  % Following p-value calc is probably only valid for n>=10
  df = n-2;
  nfact = factorial(n);
  stdK = n2const.*(2.*n+5)./9;
  if(any(ties))
    stdK = stdK - (x1Adj(3,:) + x2Adj(3,:))./18 + x1Adj(2,:).*x2Adj(2,:)./(18.*n2const.*(n-2)) + x1Adj(1,:).*x2Adj(1,:)./n2const;
  end
  stdK = sqrt(stdK);
  tail = 'b';
  switch tail
    case 'b' % 'both or 'ne'
        p = normcdf(-(abs(K)-1) ./ stdK);
        p = min(2*p, 1); % Don't count continuity correction at center twice
    case 'r' % 'right' or 'gt'
        p = normcdf(-(K-1) ./ stdK);
    case 'l' % 'left' or 'lt'
        p = normcdf((K+1) ./ stdK);
  end
end
return;



function [p, t, df] = uttest(d1, d2)
%UTTEST Student's t-test for unequal variances.
%       UTTEST(X1, X2) gives the probability that Student's t
%       calculated on data X1 and X2, sampled from distributions
%       with different variances, is higher than observed, i.e.
%       the "significance" level.  This is used to test whether
%       two sample have significantly different means.
%       [P, T] = UTTEST(X1, X2) gives this probability P and the
%       value of Student's t in T. The smaller P is, the more
%       significant the difference between the means.
%       E.g. if P = 0.05 or 0.01, it is very likely that the
%       two sets are sampled from distributions with different
%       means.
%
%       This works if the samples are drawn from distributions with
%       DIFFERENT VARIANCE. Otherwise, use TTEST.
%
%See also: TTEST, PTTEST.
[l1 c1] = size(d1) ;
n1 = l1 * c1 ;
x1 = reshape(d1, l1 * c1, 1) ;
[l2 c2] = size(d2) ;
n2 = l2 * c2 ;
x2 = reshape(d2, l2 * c2, 1) ;
[a1 v1] = avevar(x1) ;
[a2 v2] = avevar(x2) ;
df = (v1 / n1 + v2 / n2) * (v1 / n1 + v2 / n2) / ...
     ( (v1 / n1) * (v1 / n1) / (n1 - 1) + (v2 / n2) * (v2 / n2) / (n2 -1) ) ;
t = (a1 - a2) / sqrt( v1 / n1 + v2 / n2 ) ;
p = betainc( df / (df + t*t), df/2, 0.5) ;
return;


function [p, t, df] = pttest(d1, d2)
%PTTEST Student's paired t-test.
%       PTTEST(X1, X2) gives the probability that Student's t
%       calculated on paired data X1 and X2 is higher than
%       observed, i.e. the "significance" level. This is used
%       to test whether two paired samples have significantly
%       different means.
%       [P, T] = PTTEST(X1, X2) gives this probability P and the
%       value of Student's t in T. The smaller P is, the more
%       significant the difference between the means.
%       E.g. if P = 0.05 or 0.01, it is very likely that the
%       two sets are sampled from distributions with different
%       means.
%
%       This works for PAIRED SAMPLES, i.e. when elements of X1
%       and X2 correspond one-on-one somehow.
%       E.g. residuals of two models on the same data.
%
%See also: TTEST, UTTEST.
[l1 c1] = size(d1) ;
n1 = l1 * c1 ;
x1 = reshape(d1, l1 * c1, 1) ;
[l2 c2] = size(d2) ;
n2 = l2 * c2 ;
if (n1 ~= n2)
   error('PTTEST: paired samples must have the same number of elements !')
end
x2 = reshape(d2, l2 * c2, 1) ;
[a1 v1] = avevar(x1) ;
[a2 v2] = avevar(x2) ;
df  = n1 - 1 ;
cab = (x1 - a1)' * (x2 - a2) / (n1 - 1) ;
if (a1 ~= a2)
  % use abs to avoid numerical errors for very similar data
  % for which v1+v2-2cab may be close to 0.
  t = (a1 - a2) / sqrt(abs(v1 + v2 - 2 * cab) / n1) ;
  p = betainc( df / (df + t*t), df/2, 0.5) ;
else
  t = 0 ;
  p = 1 ;
end
return;


function [p, t, df] = ttest(d1, d2)
%TTEST Student's t-test for equal variances.
%       TTEST(X1, X2) gives the probability that Student's t
%       calculated on data X1 and X2, sampled from distributions
%       with the same variance, is higher than observed, i.e.
%       the "significance" level. This is used to test whether
%       two sample have significantly different means.
%       [P, T] = TTEST(X1, X2) gives this probability P and the
%       value of Student's t in T. The smaller P is, the more
%       significant the difference between the means.
%       E.g. if P = 0.05 or 0.01, it is very likely that the
%       two sets are sampled from distributions with different
%       means.
%
%       This works if the samples are drawn from distributions with
%       the SAME VARIANCE. Otherwise, use UTTEST.
%
%See also: UTTEST, PTTEST.
[l1 c1] = size(d1) ;
n1 = l1 * c1 ;
x1 = reshape(d1, l1 * c1, 1) ;
[l2 c2] = size(d2) ;
n2 = l2 * c2 ;
x2 = reshape(d2, l2 * c2, 1) ;
[a1 v1] = avevar(x1) ;
[a2 v2] = avevar(x2) ;
df = n1 + n2 - 2 ;
pvar = ((n1 - 1) * v1 + (n2 - 1) * v2) / df ;
t = (a1 - a2) / sqrt( pvar * (1/n1 + 1/n2)) ;
p = betainc( df / (df + t*t), df/2, 0.5) ;
return;


function [xbar, varx] = avevar(v)
%AVEVAR average and variance of sample.
%       AVEVAR(X) gives the average of the sample in X.
%       X is a vector of values.
%       [A, V] = AVEVAR(X) returns the average of X in A,
%       and the variance in V. The variance is corrected
%       using the two-pass formula.
%
%       Ref: [1] Chan, Golub and LeVeque. 1983. American
%                Statistician, vol. 37, pp. 242--247.
%            [2] Press et al. 1992. Numerical recipes in C.
%                Cambridge university press.
[n l] = size(v) ;
x = reshape(v, n*l, 1) ;
xbar = sum(x) / n / l ;
d = x - xbar ;
varx = ( sum(d .* d) - sum(d) * sum(d) / n / l) / (n * l - 1) ;
return;


function [p, f, df] = ftest(d1, d2)
%FTEST F-test for two samples.
%       FTEST(X1, X2) gives the probability that the F value
%       calculated as the rati of the variances of the two samples is
%       greater than observed, i.e. the significance level.
%       [P, F] = FTEST(X1, X2) gives the probability P and returns
%       the value of F.
%
%       A small value of P would lead to reject the hypothesis that
%       both data sets are sampled from distributions with the same
%       variances.
%
%See also : TTEST, TEST.
[l1 c1] = size(d1) ;
n1 = l1 * c1 ;
x1 = reshape(d1, l1 * c1, 1) ;
[l2 c2] = size(d2) ;
n2 = l2 * c2 ;
x2 = reshape(d2, l2 * c2, 1) ;
[a1 v1] = avevar(x1) ;
[a2 v2] = avevar(x2) ;
f = v1 / v2 ;
df1 = n1 - 1 ;
df2 = n2 - 1 ;
if (v1 > v2)
   p = 2 * betainc( df2 / (df2 + df1 * f), df2 / 2, df1 / 2) ;
else
   f = 1 / f ;
   p = 2 * betainc( df1 / (df1 + df2 * f), df1 / 2, df2 / 2) ;
end
if (p > 1)
   p = 2 - p ;
end   

df = [df1,df2];
return;
