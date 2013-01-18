function [f,d1f,d2f] = fctnVol(y,Omega,m)
% function [f,d1f,d2f] = fctnVol(y,Omega,m)
%
% (c) Nils Papenberg, Jens Heyder, SAFIR, Luebeck,  2006
%
% input:
%   - y     : deformation field on staggered grid
%   - Omega : image domain (for Stanford group Omega = [1 1] ever
%   - m     : number of pixels
%
% output:
%   - f     : value of volume preserving penalty function
%   - d1f   : its first
%   - d2f   : and second derivative
%

persistent D11 D12 PD21 PD22

% set default for output
f  = 0;
d1f = 0;
d2f = 0;
D11 = 0;

% case nargin == 0 is for selftesting of the function
if nargin == 0,
  clc
  Omega = [2,1];
  m     = [32,32];
  y = getGrid(Omega,m,'stg');
  fctnVol(y,Omega,m);
  return
end;

if nargout == 0,
  testMe(mfilename,y,Omega,m);
  return;
end;

% setting pixelsize (h), numver of pixels (n) and some gridsizes of the
% staggerd and the nodal grid
h    = Omega./m;
n    = m(1)*m(2);
n1   = (m(1)+1) * m(2);
n2   = m(1) * (m(2)+1);
n3   = (m(1)+1) * (m(2)+1);
h2   = prod(h);


if size(D11, 1) ~= n
  % aux matrices for the 1D problemes
  d11 = spdiags(ones(m(1)+1,1)*[-1,1],[0,1],m(1),m(1)+1)/h(1);
  d22 = spdiags(ones(m(2)+1,1)*[-1,1],[0,1],m(2),m(2)+1)/h(2);

  d12 = spdiags(ones(m(1)+1,1)*[-1,1],[-1,0],m(1)+1,m(1))/h(1);
  d12(1,1) = 0; d12(end,end) = 0;
  d21 = spdiags(ones(m(2)+1,1)*[-1,1],[-1,0],m(2)+1,m(2))/h(2);
  d21(1,1) = 0; d21(end,end) = 0;

  % projection nodal to center
  A1=spdiags(ones(m(1),2),[0 1],m(1),m(1)+1);
  A2=spdiags(ones(m(2),2),[0 1],m(2),m(2)+1);
  Pn2c=0.25*kron(A2,A1);

  % the big Ms
  D11 = [kron(speye(m(2)),d11),sparse(n,n2)];
  D22 = [sparse(n,n1),kron(d22,speye(m(1)))];

  D12 = [sparse(n3,n1),kron(speye(m(2)+1),d12)];
  D21 = [kron(d21,speye(m(1)+1)),sparse(n3,n2)];
end;

% evaluating the function
e = ones(n,1);
D11y  = D11*y;
D22y  = D22*y;
PD12  = Pn2c * D12;
PD21  = Pn2c * D21;
PD12y = PD12*y;
PD21y = PD21*y;

F  = D11y .* D22y - PD12y .* PD21y - 1;

r = (e'*h2*F);
f = r^2;

% old code
% fc = (h2 * sum((D11*y) .* (D22*y)))^2;

if nargout < 2 return; end;


dF = sdiag(D22y) * D11 + sdiag(D11y) * D22 ...
  - sdiag(PD21y) * PD12 + sdiag(PD12y) * PD21;

dr = sparse(e' * h2 * dF);
clear dF D22y D11y PD12y PD21y
d1f = 2 * r * dr;

% d1f = 2 * r * h2 * (D22y'*D11 + D11y'*D22);

if nargout < 3 return; end;
% 
% d2f = sparse(2 * dr' * dr ...
%   + 2 * r * h2 * (D11'*D22 + D22'*D11 - PD12'*PD21 + PD21'*PD12));
d2f = sparse(2 * r * h2 * (D11'*D22 + D22'*D11 - PD12'*PD21 + PD21'*PD12));
% keyboard;
return


function testMe(fctn,y,varargin);

[fc,d1f,d2f] = feval(fctn,y,varargin{:});

vc = randn(size(y));
tc = logspace(-1,-8,8);
dt = d1f*vc;
d2t = vc'*d2f*vc;

fprintf('%12s %12s %12s %12s \n','t','T0','T1','T2');
for j=1:length(tc),
  yt = y + tc(j)*vc;
  ft = feval(fctn,yt,varargin{:});

  n0 = ft-fc;
  n1 = n0 - tc(j)*dt;
  n2 = n1 -0.5*tc(j)^2*d2t;

  fprintf('%12e %12e %12e %12e \n',tc(j),norm(n0),norm(n1),norm(n2));
end;


return;


% ----------------------------------------------------------------
function out = sdiag(b)

m = length(b);
out = spdiags(b,0,m,m);

return
% ----------------------------------------------------------------



