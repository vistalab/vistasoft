function [connections]=findConnectionMatrix2(mesh)
% Finds the sparse connection matrix for a mesh
%
%  connections=findConnectionMatrix2(mesh)
%
% The mesh slots must be:
%     .vertices  (nPoints,3): 3D coords of all mesh vertices
%     .triangles (nFaces,3) : triplets of indices specifies one corner of a face triangle
%
% The returned connections is a sparse matrix (nPoints*nPoints)
%
% AUTHOR: Wade
% DATE : Last modified 020701
 
nVerts    = meshGet(mesh,'nVertices');
triangles = meshGet(mesh,'triangles')';
 
% faceIndexList defines vertices that are connected to each other:
% If two vertices are in the same row, they're in the same triangle and 
% therefore are connected

% The values here are going to be used to create scalars
% (connection_locations) that index into the connections matrix.  
% The multiplication by nVerts makes it possible to add together
% a row and column value (see below).
%
r1=(triangles(:,1))*nVerts;
r2=(triangles(:,2));
r3=(triangles(:,3));
r4=(triangles(:,2))*nVerts;
 
% Calculate the connection_locations
% These are connections between (1,2), (1,3), and (2,3)
%
connect_locations=[ (r1+r2+1) ;(r1+r3+1); (r4+r3+1) ];

[cly,clx]=ind2sub([nVerts,nVerts],connect_locations);
connections = sparse(cly,clx,1,nVerts,nVerts);

%Now make it symmetric because if a is connected to b then b is connected to a.
connections = connections+(connections');
connections = (connections~=0);

return;
