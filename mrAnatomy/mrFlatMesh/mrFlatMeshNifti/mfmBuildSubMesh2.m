function [unfoldMesh, nFaces] = mfmBuildSubMesh2(mesh, perimeterEdges, insideNodes, orderedUniquePerimeterPoints)
% Create a portion of the mesh from a larger mesh
%
%  [unfoldMesh, nFaces] = ...
%      mfmBuildSubMesh2(mesh, perimeterEdges, insideNodes, ...
%                orderedUniquePerimeterPoints);
%
% This routine begins with the original large mesh and extracts a
% topologically correct sub-mesh based on the perimeter edges and inside
% nodes.
%
% See also:  unfoldMeshFromGUI
%

% Connection matrix of internal points
unfoldMesh.connectionMatrix = mesh.connectionMatrix(insideNodes,insideNodes);

% Copy mesh dta to unfoldMesh.  Note the name change.  
unfoldMesh.normal        = mesh.normals(:,insideNodes)';
unfoldMesh.uniqueVertices= mesh.vertices(:,insideNodes)';
unfoldMesh.uniqueCols    = mesh.colors(:,insideNodes)';
unfoldMesh.dist          = mesh.dist(insideNodes);
unfoldMesh.triangles     = mesh.triangles(:,insideNodes)';

% We need to get uniqueFaceIndexList for the unfoldMesh
indicesOfFacesInSubGroup = findFacesInGroup2(mesh,insideNodes);
% subGroupFaces    = mesh.uniqueFaceIndexList(indicesOfFacesInSubGroup,:);
subGroupFaces    = mesh.triangles(:,indicesOfFacesInSubGroup)';

nFaces = size(subGroupFaces,1);

% Get a lookup table for converting indices into the full node array into
% indices to the unfold mesh nodes.  
lookupTable = zeros(meshGet(mesh,'nVertices'),1);
lookupTable(insideNodes) = 1:length(insideNodes);

% Use the lookup table to convert our list of face indices so that they index into unfoldMesh.uniqueVertices.
sgf = lookupTable(subGroupFaces(:)+1);
unfoldMesh.uniqueFaceIndexList = reshape(sgf,nFaces,3);

% Convert the edges to feed into orderMeshPerimeterPoints
fullEdgePointList=perimeterEdges(:);

% How many edges do we have?
[numEdges,x]=size(perimeterEdges); %#ok<NASGU>

newEdges=zeros((numEdges*2),1);

for t=1:(numEdges*2)  
    newEdges(t) = find(insideNodes==fullEdgePointList(t));
end

% newEdges = reshape(newEdges,numEdges,2);

% Find the perimeter points in the sub mesh.
unfoldMesh.orderedUniquePerimeterPoints = ...
    zeros(length(orderedUniquePerimeterPoints),1);

for t=1:length(orderedUniquePerimeterPoints)
    unfoldMesh.orderedUniquePerimeterPoints(t) = ...
        find(insideNodes==orderedUniquePerimeterPoints(t));
end

return;