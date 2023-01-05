function [D,rho,dD,drho,d2Phi] = MI(Rc,Tc,Omega,m,varargin)
h   = Omega./m;
hd  = prod(h);
PARA = varargin{1};
doDerivative = (nargout > 3);

% D   = phi(rho(y))
% dD  = dPhi(res(y)) * dRes(y)
% d2D = res(y)' * d2Phi(res(y)) * dRes(y) + stuff we don't consider
    
% example MI:
%   phi   = res' * log(res + tol) + ...
%   dPhi  = log(res + tol) + res./(res + tol) + ...
%   d2Phi = (res + 2*tol)./(res + tol)^2 + ...
%   res   = rho(T,R)
%   dRes  = drho, see pdfestimate

tol         = PARA.entropyTol;
[rho,drho]  = pdfestimate(Rc,Tc,PARA,doDerivative);
[n1,n2]     = size(rho);
    
rhoR = sum(rho,2);
rhoT = sum(rho,1)';
rho  = rho(:);
    
D    = rhoR'*log(rhoR+tol)+rhoT'*log(rhoT+tol) - rho'*log(rho+tol);
     
if ~doDerivative, return; end;

SR    = sparse(kron(ones(1,n2),speye(n1,n1)));
ST    = sparse(kron(speye(n2,n2),ones(1,n1)));
    
dPhi  = ...
   (log(rhoR+tol)+rhoR./(rhoR+tol))'*SR ...
  +(log(rhoT+tol)+rhoT./(rhoT+tol))'*ST ...
  -(log(rho +tol)+rho ./(rho +tol))';
     
dD    = dPhi * drho;
    
d2Phi = ...
  SR'*sdiag((rhoR + 2*tol)./(rhoR+tol).^2)*SR ...
  +ST'*sdiag((rhoT + 2*tol)./(rhoT+tol).^2)*ST ...
  -sdiag((rho + 2*tol)./(rho+tol).^2);
       
a     = 1/sqrt(PARA.ngvR*PARA.ngvT);
a     = 1e0;
d2Phi = - a * d2Phi;
     
return;
