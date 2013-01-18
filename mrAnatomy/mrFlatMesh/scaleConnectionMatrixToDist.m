function N=scaleConnectionMatrixToDist(d3d)
% N=scaleConnectionMatrixToDist(N,d3d);
% PURPOSE: N is a connection matrix weighted so that the sum of all its
% rows is 1 and each non-zero entry on a row is the same. 
% When used in unfolding, this places each 2D node at the geometrical
% center of its neighbours.
% BUT: Computing the 3D neighbour distances is trivial. What happens if we
% weight the connection matrix to take account of these distances?
% Specifically:
% For an IxI connection matrix (where I is the number of nodes),
% let x(i,j) be the value of the entry at the ith row and jth column.
% Then the requirement is that sum(x(i,j) from j=1 to j=I ==1 
% Say we know the 3d inter-node distances so that dist3d is an IxI matrix
% Then we basically operate on dist3d so that the sum of the rows is still
% 1 but each entry is (total-dist3d(i,j))/(n-1)(total)
% Where total is the total of all the lengths attached to node(i) and n is
% the number of nodes attached to that node.
% The idea is to weight the connection matrix so that points tend to be
% placed closer to those points that they are close to in 3D.

[sy sx]=size(d3d);
sumDist=sum(d3d,2);
N=(d3d~=0); 
nConnections=sum(N,2);
N=N*(spdiags(sumDist,0,sy,sx));
scaleFact=spdiags(1./((nConnections(:)-1).*sumDist(:)),0,sy,sx);
N=N-d3d;
N=N*scaleFact;
N=N';


