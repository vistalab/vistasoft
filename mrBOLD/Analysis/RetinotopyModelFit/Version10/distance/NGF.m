function [D,res,dD,dres,d2Phi] = NGF(Rc,Tc,Omega,m,varargin)

h   = Omega./m;
hd  = prod(h);
edge = varargin{1}.edge;
doDerivative = (nargout > 3);

% D   = phi(res(y))
% dD  = dPhi(res(y)) * dRes(y)
% d2D = res(y)' * d2Phi(res(y)) * dRes(y) + stuff we don't consider
    
% example NGF:
%   phi = hd/2 res'*res,  dPhi = hd * res, d2Phi = hd
%   dR_i  = \nabla R_i / |\nabla R_i|_edge
%   res = (\nabla T(y_i)' * dR_i) / ( |\nabla T(y_i)|_edge )
%   dRes = complicated, see below

[G1,G2,G3] = getGrad('c',Omega,m);
if isempty(G3), G3 = 0; end;

d1R = G1 * Rc(:);    d2R = G2 * Rc(:);    d3R = G3 * Rc(:);
d1T = G1 * Tc(:);    d2T = G2 * Tc(:);    d3T = G3 * Tc(:);

ndR = sqrt(d1R.^2 + d2R.^2 + d3R.^2 + edge^2);
ndT = sqrt(d1T.^2 + d2T.^2 + d3T.^2 + edge^2);
     
nd1R = d1R./ndR;      %nd1T = d1T./ndT;
nd2R = d2R./ndR;      %nd2T = d2T./ndT;
nd3R = d3R./ndR;      %nd3T = d3T./ndT;
      
res1 = (nd1R.*d1T + nd2R.*d2T + nd3R.*d3T);
res2 = 1./ndT;
res  = res1 .* res2;

D    = -hd/2 * res' * res;

if ~doDerivative, return; end;

dRes1 = sdiag(nd1R)*G1 + sdiag(nd2R)*G2 + sdiag(nd3R)*G3;
dRes2 = -sdiag(1./ndT.^3)*(sdiag(d1T)*G1 + sdiag(d2T)*G2 + sdiag(d3T)*G3);
dRes  = (sdiag(res2)*dRes1 + sdiag(res1)*dRes2) * dTc;
    
dD    = -hd * res' * dRes;
d2Phi = hd; % note the missing minus sign is not a bug!
return;