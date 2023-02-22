function PARA = setMIpara(PARA,varargin)

% default parameter:
kernel  = 'cos4';
sigma   = 32;
minR    = -50;  maxR    = 300; ngvR = 8;
minT    = -50;  maxT    = 300; ngvT = 8;
entropyTol = 1e-8;


% overwrite PARA
for k=1:length(varargin)/2,
  str = sprintf('PARA=setfield(PARA,''%s'',varargin{%d});',varargin{2*k-1},2*k);
  disp(str);
  eval(str);
end;

% enpack PARA
fn = fieldnames(PARA);
for j=1:length(fn),
  str = sprintf('%s=getfield(PARA,fn{%d});',fn{j},j);
%   disp(str);
  eval(str);
end;

% check integration
tol     = 1e-2;
maxngv  = 512;

while 1,
  gvR  = linspace(minR,maxR,ngvR);
  yR   = feval(kernel,gvR,sigma);
  intR = sum(yR)*(gvR(2)-gvR(1));
  if abs(intR-1) <= tol, break; end;
  ngvR = 2*ngvR;
  if ngvR>maxngv, error('to many bins for grayvalues of R'); end;
end;
while 1,
  gvT  = linspace(minT,maxT,ngvT);
  yT   = feval(kernel,gvT,sigma);
  intT = sum(yT)*(gvT(2)-gvT(1));
  if abs(intT-1) <= tol, break; end;
  ngvT = 2*ngvT;
  if ngvT>maxngv, error('to many bins for grayvalues of T'); end;
end;

PARA.kernel = kernel;
PARA.sigma  = sigma;
PARA.minR   = minR;
PARA.maxR   = maxR;
PARA.ngvR   = ngvR;
PARA.gvR    = gvR;
PARA.minT   = minT;
PARA.maxT   = maxT;
PARA.ngvT   = ngvT;
PARA.gvT    = gvT;
PARA.entropyTol = entropyTol;

return;
% ------------------------------------------------------------------------------
