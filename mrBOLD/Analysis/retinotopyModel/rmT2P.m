function p=rmT2P(t,df,units);
% rmT2P - convert statistical t-values to p-values
% p=rmT2P(t[,df[,units]]); 
%
% t     : statistical t-values
% df    : degrees of freedom [default = Inf]
% units : 'p' [default], 'log10p'
%

% 2006/01 SOD: wrote it.

if ieNotDefined('t'),     error('Need t'); end;
if ieNotDefined('df'),    df    = Inf;     end;
if ieNotDefined('units'), units = 'p';     end;

% preserve the sign of t in p values
tsign = sign(t);
tsign(tsign==0)=1;
% make sure t is a real number
t(isinf(t))     = 50; % infinite will go to a large t value
t(~isfinite(t)) =  0; % others (NaN) go to 0
t               = abs(t);

% Find the upper tail probs of the two-tailed t-distribution:
if df==Inf,
  p=0.5*erfc(t/sqrt(2));
else,  
  p=0.5*betainc(df./(df+t.^2),df/2,0.5);
end;

% convert
switch units
 case 'log10p',
  p(p<1e-50) = 1e-50; % remove 0
  p       = -log10(abs(p));
  p(p>50) = 50;
  p       = p .* tsign;
 case 'p', 
  p = p.*tsign;
 otherwise,
  disp(sprintf('Unknown unit: %s',units));
end;

return;

