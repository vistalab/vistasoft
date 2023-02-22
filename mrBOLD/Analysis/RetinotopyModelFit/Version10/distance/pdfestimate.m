 function [rho,drho,d2rho] = pdfestimate(R,T,para,doderivatives);
%function [rho,drho,d2rho] = pdfestimate(R,T,para,doderivatives);
% JM/2004/04/29

if ~exist('para','var'),          
  para = setMIpara([]);
end;
if ~exist('doderivatives','var'), 
  doderivatives = 1;
end;
doderivatives = doderivatives & (nargout>1);

R     = R(:); 
T     = T(:);
lenT  = length(T);
ngvR  = length(para.gvR);
ngvT  = length(para.gvT);
gvR   = reshape(para.gvR,ngvR,1);
gvT   = reshape(para.gvT,1,ngvT);
sigma = para.sigma;

rho   = zeros(ngvR,ngvT);
drho  = [];
d2rho = [];

if length(gvR) == 1,
  kRmin = ones(length(T),1); kRmax = kRmin;
else  
  hR = diff(gvR(1:2));
  kRmin = ceil((R-sigma-gvR(1))/hR)+1;  J = find(kRmin<1);    kRmin(J) = 1;
  kRmax = floor((R+sigma-gvR(1))/hR)+1; J = find(kRmax>ngvR); kRmax(J) = ngvR;
end;
 
if length(gvT) == 1,
  kTmin = ones(length(T),1); kTmax = kTmin;
else  
  hT = diff(gvT(1:2));
  kTmin = ceil((T-sigma-gvT(1))/hT)+1;  J = find(kTmin<1);    kTmin(J) = 1;
  kTmax = floor((T+sigma-gvT(1))/hT)+1; J = find(kTmax>ngvT); kTmax(J) = ngvT;
end;

l1 = max(kRmax-kRmin)+1;
l2 = max(kTmax-kTmin)+1;
drho = spalloc(ngvR*ngvT,lenT,100*lenT);

% if doderivatives,
%   l1 = max(kRmax-kRmin)+10;
%   l2 = max(kTmax-kTmin)+10;
%    disp([l1,l2])
%   drho  = zeros(ngvR*ngvT,lenT);
%   d2rho = sparse(ngvR*ngvT,lenT);
%   whos
% end;


for j=1:lenT,  
  JT = kTmin(j):kTmax(j);
  JR = kRmin(j):kRmax(j);  
  GR = feval(para.kernel,gvR(JR)-R(j),sigma);
  switch nargout,
    case 1, GT            = feval(para.kernel,gvT(JT)-T(j),sigma);
    case 2, [GT,dGT]      = feval(para.kernel,gvT(JT)-T(j),sigma);
    case 3, [GT,dGT,d2GT] = feval(para.kernel,gvT(JT)-T(j),sigma);
  end;
  
  rho(JR,JT) = rho(JR,JT) + GR*GT;
  
  if nargout > 1,
    drhoj = sparse(ngvR,ngvT);
    drhoj(JR,JT) = -GR*dGT;
    drho(:,j) = sparse(drhoj(:));
%     drho(:,j) = drhoj(:);

    if nargout > 2,
      d2rhoj = sparse(ngvR,ngvT);
      d2rhoj(JR,JT) = GR*d2GT;
      d2rho(:,j) = sparse(d2rhoj(:));
    end
  end
  
end

rho   =   rho/lenT;
drho  =  drho/lenT;
d2rho = d2rho/lenT;

return;

if nargout < 2, return;  end;

Irho = hR*hT*sum(rho(:))
if abs(Irho-1) > 1e-2,
   fprintf('sum(p(:))=%12.4e\n',Irho);
end;

dv = randn(size(T));

keyboard

for j=0:-1:-6,
  tau = 10^j;
  rhov = pdfestimate(R,T+tau*dv,para);
  n1 = norm(rho-rhov);  
  n2 = norm(rho(:)+tau*drho*reshape(dv,prod(size(dv)),1)-rhov(:));
  n3 = 0;
%  n3 = norm(rho(:)+tau*drho*reshape(dv,prod(size(dv)),1)...
%    +tau^2/2*d2rho*reshape(dv,prod(size(dv)),1).^2-rhov(:));
  fprintf('%12.4e %12.4e %12.4e %12.4e\n',tau,n1,n2,n3);
end;

return;
% ------------------------------------------------------------------------------
