function p=t2p(t,n,df,units)
% t2p - get p-value from t-statistical values
% p=t2p(t,n,df,units);
%  t     = t-statistical values
%  n     = number of comparisons for Bonferroni correction [1]
%  df    = degrees of freedom [Inf]
%  units = 'p', 'log10p' [p]

% 08/2005 SOD: created it.

% input checks and defaults
if ~exist('t','var') || isempty(t),   error('Need t');   end
if ~exist('n','var') || isempty(n),   n = 1;             end
if ~exist('df','var') || isempty(df), df = Inf;          end
if ~exist('units','var') || isempty(units), units = 'p'; end

% preserve the sign of t in p values
tsign = sign(t);
tsign(tsign==0)=1;
t = abs(t);

% Find the upper tail probs of the two-tailed t-distribution:
if df==Inf,
  p=0.5*erfc(t/sqrt(2));
else  
  p=0.5*betainc(df./(df+t.^2),df/2,0.5);
end;

% Bonferroni
p=(n+1).*p;
p(p>1)=1; % otherwise log10p is funny

% convert
switch units
 case 'log10p',
  p(p==0) = 10^-50; % remove 0
  p       = -log10(abs(p)) .* tsign;
 case 'p', 
  % preserve the sign of t in p values
  p = p.*tsign;
 otherwise,
  disp(sprintf('Unknown unit: %s',units));
end;

return;
