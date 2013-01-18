function [N, P, internalNodes] = findNPConnection(mesh);
%
% [N, P, internalNodes] = findNPConnection(mesh)
%
% AUTHOR: Wade
%
% Create the N and P connection matrices used to solve
% the linear equations for flattening.  N represents the
% connections between internal nodes, appropriately weighted,
% and P represents the connections between fixed nodes, again
% appropriately weighted.
%
% The appropriate weighting in this case is:
% N is an (nxn) matrix whose (i,j)th entry is 1/mi where mi is the number
% of edges connected to the ith node or 0 if the nodes aren't connected.
% DATE : 020107 Last modified

internalNodes = setdiff((1:length(mesh.uniqueVertices)), mesh.orderedUniquePerimeterPoints);
intMat = mesh.connectionMatrix(internalNodes,internalNodes);

nVerts = length(mesh.uniqueVertices);
%traceMat=speye(nVerts,nVerts);
%diag_indices=sub2ind([nVerts,nVerts],(1:nVerts),(1:nVerts));

mP = 1./sum(mesh.connectionMatrix);
traceMat = sparse(1:nVerts, 1:nVerts, mP);

% This is fast becausue it's sparse
conMat = traceMat*mesh.connectionMatrix;

semiConMat = conMat(internalNodes,:);

P = semiConMat(:, mesh.orderedUniquePerimeterPoints);
N = semiConMat(:, internalNodes);

return