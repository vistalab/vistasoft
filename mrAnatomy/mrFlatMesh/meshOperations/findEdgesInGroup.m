function groupEdgeList=findEdgesInGroup(mesh,nodes)
% Create a list of edges in a given group of nodes
% See also findFacesInGroup

nVerts=length(mesh.uniqueVertices);

% This is wasteful - don't make two new sparse matrices! Just fiddle the one you've got....
% Want to eliminate entries that are not in (nodes,nodes);
diagMat=sparse(nodes,nodes,ones(length(nodes),1),nVerts,nVerts);

% make a connection matrix of just edges in this group
mesh.connectionMatrix=mesh.connectionMatrix*diagMat;
mesh.connectionMatrix=((mesh.connectionMatrix')*diagMat)';


[groupEdgeList1,groupEdgeList2]=find(triu(mesh.connectionMatrix));
groupEdgeList=[groupEdgeList1,groupEdgeList2];

groupEdgeList=sort(groupEdgeList,2); % Sort them so that the lowest numbered nodes appear first
