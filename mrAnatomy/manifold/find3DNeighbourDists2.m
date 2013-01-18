function  distSQ = find3DNeighbourDists2(mesh,scaling)
%
%   distSQ = find3DNeighbourDists2(mesh,scaling);
%
% Return a list of the (squared) distances between each node and its
% neighbours. If there are n connections in the mesh, there should be n
% entries in distSQ See also find2DNeighboutDists - does the same thing
% with the 2d mesh. 
%
% ARW 031201 - Now takes a scaling argument (equiv of dimdist for
% mrManDist) The returned distances are now in millimeters.  
%
% AUTHOR: WADE
% DATE : 062700

if notDefined('scaling'), scaling=[1 1 1]; end

spX = mesh.connectionMatrix;
spY = mesh.connectionMatrix;
spZ = mesh.connectionMatrix;
nVerts = length(mesh.connectionMatrix);

% Comments anyone?
xI = sparse((1:nVerts),(1:nVerts),mesh.vertices(1,:),nVerts,nVerts)*scaling(1);
yI = sparse((1:nVerts),(1:nVerts),mesh.vertices(2,:),nVerts,nVerts)*scaling(2);
zI = sparse((1:nVerts),(1:nVerts),mesh.vertices(3,:),nVerts,nVerts)*scaling(3);

spX = spX*xI;
spY = spY*yI;
spZ = spZ*zI;

% Cols of sp(X,Y,Z) are now ordinates of corresponding vertices
spX = spX - spX';
spY = spY - spY';
spZ = spZ - spZ';
distSQ = (spX.^2 + spY.^2 + spZ.^2);

return;
