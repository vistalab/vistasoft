function groupEdgeList = findEdgesInGroup2(msh,vertexIndices)
% Create a list of edges in a given list of vertexIndices
%
%  groupEdgeList = findEdgesInGroup2(msh,vertexIndices)
%
% See also findFacesInGroup2

nVerts = meshGet(msh,'nVertices');

% This is wasteful - don't make two new sparse matrices! 
% Just fiddle the one you've got....
% Want to eliminate entries that are not in (vertices,vertices);
diagMat = sparse(vertexIndices,vertexIndices,ones(length(vertexIndices),1),nVerts,nVerts);

% make a connection matrix of just edges in this group
msh.connectionMatrix = msh.connectionMatrix*diagMat;
msh.connectionMatrix = ((msh.connectionMatrix')*diagMat)';

[groupEdgeList1,groupEdgeList2] = find(triu(msh.connectionMatrix));
groupEdgeList = [groupEdgeList1,groupEdgeList2];

% Sort them so that the lowest numbered vertexIndices appear first
groupEdgeList = sort(groupEdgeList,2); 

return;
