function badPoints=findBadPerimNodes(mesh,perimeterEdges)
% function badPoints=findBadPerimNodes(mesh,perimeterEdges)
% Finds points on the perimeter that are connected to more than two other perimeter points
% ARW 031501 - Wrote it

nVerts=length(mesh.connectionMatrix); % Total number of vertices in the full connection matrix

edgePoints=unique(perimeterEdges(:)); % List of nodes that are on the perimeter
[y x]=size(mesh.connectionMatrix); % = nVerts

% Generate a connection matrix using only the edges - make sure it's symmetric
ec=sparse(perimeterEdges(:,1),perimeterEdges(:,2),1,nVerts,nVerts);
ec=ec+ec';
edgeConMat=sparse((ec~=0));
[eY,eX]=size(edgeConMat);

nConnects=sum(edgeConMat,2); % How many points on each row?
badPoints=find(nConnects>2);