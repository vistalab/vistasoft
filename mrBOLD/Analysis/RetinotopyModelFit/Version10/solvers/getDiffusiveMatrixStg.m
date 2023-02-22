%==============================================================================
% Copyright (C) 2005, Jan Modersitzki and Nils Papenberg, see copyright.m,
% this file is part of the FLIRT Package, all rights reserved;
% http://www.math.uni-luebeck.de/SAFIR/FLIRT-MATLAB.html
%==============================================================================
% function [B,Bstr] = getDiffusiveMatrix(Omega,m);
% generates the elastic matrix B for the domain Omega with resolution m,
% by default, mu = 1, lambda = 0;
%==============================================================================
function [B,Bstr] = getDiffusiveMatrixStg(Omega,m)

Bstr = 'diffusive-stg';
h = Omega./m;

d11 = spdiags(ones(m(1),1)*[-1,1],[0,1],m(1),m(1)+1)/h(1);
d12 = spdiags(ones(m(2)-1,1)*[-1,1],[0,1],m(2)-1,m(2))/h(2);
d21 = spdiags(ones(m(1)-1,1)*[-1,1],[0,1],m(1)-1,m(1))/h(1);
d22 = spdiags(ones(m(2),1)*[-1,1],[0,1],m(2),m(2)+1)/h(2);

D11 = sparse(kron(speye(m(2)),d11));
D12 = sparse(kron(d12,speye(m(1)+1)));
D21 = sparse(kron(speye(m(2)+1),d21));
D22 = sparse(kron(d22,speye(m(1))));


% build the diffusive operator 
%
%      | \nabla 0      |
%  B = |               |
%      | 0      \nabla |
%      |               |
% B[U] = [\partial_1 U1,\partial_2 U1, \partial_1 U2,\partial_2 U2]

n1 = (m(1)+1)*m(2);
n2 = m(1)*(m(2)+1);
j1 = size(D11,1);
j2 = size(D12,1);
j3 = size(D21,1);
j4 = size(D22,1);

B = [  D11,sparse(j1,n2);
       D12,sparse(j2,n2);
       sparse(j3,n1),D21;
       sparse(j4,n1),D22]; 
return;
%==============================================================================
