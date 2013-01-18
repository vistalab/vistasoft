function outNodes=removeHangingNodes(mesh,nodeIndices)
% function outNodes=removeHangingNodes(mesh,insideNodes)
%
% AUTHOR:  Wade
%
% PURPOSE:
% A group of nodes defines a set of triangular faces. However, it is possible that some nodes are not part of a face
% Get rid of these.

nVerts=length(mesh.uniqueVertices);

% Now find all the faces contained in this group
faceList=findFacesInGroup(mesh,nodeIndices);


goodFaceNodes=mesh.uniqueFaceIndexList(faceList,:);
newNodeIndices=unique(goodFaceNodes(:));

eliminatedNodes=length(nodeIndices)-length(newNodeIndices);
 
%disp('Eliminated nodes:');
%disp(eliminatedNodes);
outNodes=newNodeIndices;
