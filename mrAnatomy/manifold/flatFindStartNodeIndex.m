function startNodeIdx = flatFindStartNodeIndex(mesh)
%
%  startNodeIdx = flatFindStartNodeIndex(mesh)
%
%Author: Wandell
%Purpose:
%  Use the data in the flat.mat type file for the mesh and determine the
%  index into the start node used for flattening the Layer 0 (white matter
%  boundary) mesh. 
%  
%  Called from flatAdjustSpacing

% We need to make sure that the inputs to assignToNearest each have 3 rows
if ~isequal(size(mesh.uniqueVertices, 1), 3), 
    mesh.uniqueVertices = mesh.uniqueVertices'; 
end
if ~isequal(size(mesh.startCoords, 1), 3), 
    mesh.startCoords = mesh.startCoords'; 
end

% This is the line used in mrFlatMesh.  There it is used before we have
% clipped down the matrices.
[startNodeIdx,snDist]=assignToNearest(mesh.uniqueVertices,mesh.startCoords); 

% Not sure this is the right function.
% l = find(ismember(round(mesh.uniqueVertices),mesh.startCoords,'rows'));
% startNodeIdx = l(1);

return;