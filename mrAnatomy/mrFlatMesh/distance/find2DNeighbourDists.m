function dist2DSQ=find2DNeighbourDists(mesh);
% AUTHOR : WADE
% DATE : 062700
% Purpose
% Want to compare 2D and 3D distances
% find3DNeighbourDists already computes the 3D distances between neighbouring nodes in 3D
% This routine does the same thing in 2D - can be used to find out how well the flattening did
% wrt preserving lengths.

% After flattening, mesh.X_zero contains locations of perimeter points
% mesh.X contains 2D locations of internal points

spX=mesh.connectionMatrix;
spY=mesh.connectionMatrix;
nVerts=length(mesh.connectionMatrix);

dx=zeros(nVerts,1);
dy=zeros(nVerts,1);
dx(mesh.internalNodes)=mesh.X(:,1);
dy(mesh.internalNodes)=mesh.X(:,2);
dx(mesh.orderedUniquePerimeterPoints)=mesh.X_zero(:,1);
dy(mesh.orderedUniquePerimeterPoints)=mesh.X_zero(:,2);

xI=sparse((1:nVerts),(1:nVerts),dx,nVerts,nVerts);
yI=sparse((1:nVerts),(1:nVerts),dy,nVerts,nVerts);

spX=spX*xI;
spY=spY*yI;

% Cols of sp(X,Y) are now ordinates of corresponding vertices
spX=spX-spX';
spY=spY-spY';

dist2DSQ=(spX.^2+spY.^2);
