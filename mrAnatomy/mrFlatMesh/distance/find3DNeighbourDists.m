function [dist]=find3DNeighbourDists(mesh,scaling);
% function [dist]=find3DNeighbourDists(mesh,scaling);
% AUTHOR: WADE
% DATE : 062700
% PURPOSE : Return a list of the distances between each node and its neighbours.
% If there are n connections in the mesh, there should be n entries in distSQ
% See also find2DNeighboutDists - does the same thing with the 2d mesh. 
% ARW 031201 - Now takes a scaling argument (equiv of dimdist for mrManDist)
% This scales distances along the appropriate matrix dimensions
% ARW 082702 - Now returns the abs distance not the squared one.
if (~exist('scaling'))
	scaling=[1 1 1];
end

spX=mesh.connectionMatrix;
spY=mesh.connectionMatrix;
spZ=mesh.connectionMatrix;
nVerts=length(mesh.connectionMatrix);

% What am I doing here?
 %   S = SPARSE(i,j,s,m,n,nzmax) uses the rows of [i,j,s] to generate an
 %   m-by-n sparse matrix with space allocated for nzmax nonzeros.  The
 %   two integer index vectors, i and j, and the real or complex entries
 %   vector, s, all have the same length, nnz, which is the number of
 %   nonzeros in the resulting sparse matrix S .  Any elements of s 
 %   which have duplicate values of i and j are added together.

xI=sparse((1:nVerts),(1:nVerts),mesh.uniqueVertices(:,1),nVerts,nVerts)*scaling(1);
yI=sparse((1:nVerts),(1:nVerts),mesh.uniqueVertices(:,2),nVerts,nVerts)*scaling(2);
zI=sparse((1:nVerts),(1:nVerts),mesh.uniqueVertices(:,3),nVerts,nVerts)*scaling(3);
% So we're creating 3 diagonal sparse matrices.
% They contain the x,y,z coordinates of the uniqueVertices on their diagonals.

spX=spX*xI;
spY=spY*yI;
spZ=spZ*zI;

% What does this mean? If there's a connection at between nodes i and j, there will be a '1' in
% the conmat at i,j (and j,i...). 
% The above multiplication means that all the '1's (connections) in column j will be
% replaced by the X, Y, or Z ordinates of the j'th node.


% Cols of sp(X,Y,Z) are now ordinates of corresponding vertices
spX=spX-spX'; % Smart eh? So the i,jth entry is the X ordinate of the j'th node. And the j,i'th entry is the X ordinate ofthe 
              % ith node. So this subtraction calculates the X distance between them.
spY=spY-spY';
spZ=spZ-spZ';
dist=sqrt(spX.^2+spY.^2+spZ.^2); % And this just sums the squares of the X,Y and Z distances. Take the sqrt of this matrix to get the
                               % edge distances.
                               
