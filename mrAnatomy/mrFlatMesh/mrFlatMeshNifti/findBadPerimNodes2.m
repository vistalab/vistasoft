function badPoints = findBadPerimNodes2(mesh,perimeterEdges)
% Detects perimeter points connected to more than two other perimeter
% points; these are bad
%
%  badPoints = findBadPerimNodes2(mesh,perimeterEdges)
%
% ARW 031501 - Wrote it

% Total number of vertices in the full connection matrix
nVerts=length(mesh.connectionMatrix); 

% edgePoints = unique(perimeterEdges(:));   % List of nodes that are on the perimeter
% [y x] = size(mesh.connectionMatrix);      % = nVerts

% Generate a connection matrix using only the edges - make sure it's symmetric
ec = sparse(perimeterEdges(:,1),perimeterEdges(:,2),1,nVerts,nVerts);
ec = ec+ec';
edgeConMat = sparse((ec~=0));
% [eY,eX] = size(edgeConMat);

nConnects = sum(edgeConMat,2); % How many points on each row?
badPoints = find(nConnects>2);

return;