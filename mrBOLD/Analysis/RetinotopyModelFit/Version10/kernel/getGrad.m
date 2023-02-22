function [G1,G2,G3] = getGrad(grid,Omega,m);

dim = length(Omega);
h = Omega./m;
G1 = [];
G2 = [];
G3 = [];

switch grid,
  case {'cell-centered','cell centered','centered','c'},

    d1 = spdiags(ones(m(1),1)*[-1,1],[-1,1],m(1),m(1))/(2*h(1)); 
    d1([1,end]) = d1([2,end-1]);
    d2 = spdiags(ones(m(2),1)*[-1,1],[-1,1],m(2),m(2))/(2*h(2)); 
    d2([1,end]) = d2([2,end-1]);
    if dim > 2,
      d3 = spdiags(ones(m(3),1)*[-1,1],[-1,1],m(3),m(3))/(2*h(3));
      d3([1,end]) = d3([2,end-1]);
    else
      m(3) = 1;
    end;
    
    G1 = sparse(kron(kron(speye(m(3)),speye(m(2))),d1));
    G2 = sparse(kron(kron(speye(m(3)),d2),speye(m(1))));
    if dim>2,
      G3 = sparse(kron(kron(d3,speye(m(2))),speye(m(1))));
    end;
    return;
    
  case {'staggered','s'},
    fprintf('not debugged %s\n',mfilename)



    D21 = kron(kron(speye(m(3)),speye(m(2)+1)),d1);
    D22 = kron(kron(speye(m(3)),d22),speye(m(1)));
    D23 = kron(kron(d3,speye(m(2)+1)),speye(m(1)));

    D31 = kron(kron(speye(m(3)+1),speye(m(2))),d1);
    D32 = kron(kron(speye(m(3)+1),d2),speye(m(1)));
    D33 = kron(kron(d33,speye(m(2))),speye(m(1)));
  otherwise,
    error(grid);
end;

