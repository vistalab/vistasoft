function [D,res,dD,dRes,d2Phi] = SSD(Rc,Tc,Omega,m,varargin)
h   = Omega./m;
hd  = prod(h);
res   = Tc-Rc;
D     = hd/2 * res' * res;
    
% D   = phi(res(y))
% dD  = dPhi(res(y)) * dRes(y)
% d2D = res(y)' * d2Phi(res(y)) * dRes(y) + stuff we don't consider

% example SSD:
%   phi = hd/2 res'*res,  dPhi = hd * res, d2Phi = hd
%   res = T(y) - R,       dRes = 1;

res   = Tc-Rc;
D     = hd/2 * res' * res;

doDerivative = (nargout > 3);

if ~doDerivative, return; end;

dRes  = 1;
dD    = hd * res';
d2Phi = hd;
return;
