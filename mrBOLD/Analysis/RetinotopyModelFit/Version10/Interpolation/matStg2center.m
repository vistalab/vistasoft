function P = matStg2center(m);

a1  = spdiags(ones(m(1),1)*[1,1],0:1,m(1),m(1)+1);
a2  = spdiags(ones(m(2),1)*[1,1],0:1,m(2),m(2)+1);

n  = prod(m);
n1 = (m(1)+1)*m(2);
n2 = (m(2)+1)*m(1);

P = [kron(speye(m(2),m(2)),a1),sparse(n,n2)
     sparse(n,n1),kron(a2,speye(m(1),m(1)))]/2;
   




