function [outNodes, nEliminated] = removeHangingNodes2(mesh,nodeIndices)
% If there are nodes not part of a face, eliminate them from the mesh
%
%  outNodes=removeHangingNodes2(mesh,insideNodes)
%
% A group of nodes defines a set of triangular faces. However, it is
% possible that some nodes are not part of a face Get rid of these.
%
% Some triangles have one or two vertices outside the perimeter.  These
% triangles will not be included; any nodes that are within the perimeter
% but only part of these excluded triangles are removed here.

% nVerts=length(mesh.vertices);

% Now find all the faces contained in this group
faceList = findFacesInGroup2(mesh,nodeIndices);

goodFaceNodes  = mesh.triangles(:,faceList) + 1;  %3xN list

% Just the indices to the unique vertices
newNodeIndices = unique(goodFaceNodes(:));        

nEliminated = length(nodeIndices)-length(newNodeIndices);
 
outNodes = newNodeIndices;

return;
