function connectSparse = Graph2Connection(UNFOLD)
% 
%   connectSparse = Graph2Connection(UNFOLD)
% 
% AUTHOR:  Wandell
% DATE:   09.06.99
% PURPOSE:
%    Create a sparse matrix of the connections in a gray graph.
% 
% 

nodes = UNFOLD.nodes;
edges = UNFOLD.edges;

numNodes = size(nodes,2);
connectSparse = sparse(numNodes,numNodes);

for ii=1:numNodes
  l1 = mrUGetNeighbors(UNFOLD,ii);
  connectSparse(ii,l1) = 1;
end

return;

% Debug
% 
