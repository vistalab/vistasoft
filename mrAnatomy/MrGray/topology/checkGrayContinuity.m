function nReached = checkGrayContinuity(nodes,edges,dimdist)
% 
%   nReached = checkGrayContinuity(nodes,edges,dimdist)
% 
% AUTHOR:  Wandell 
% PURPOSE: Check whether a graph structure is fully connected.
% 

if nargin < 3
  error('checkGrayContinuity:  Must have 3 input arguments')
end

[d nReached] = mrManDist(nodes,edges,1,dimdist,-1);
numNodes = size(nodes,2);
if (nReached ~= numNodes)
  fprintf('Number of nodes: %d\n',numNodes);
  fprintf('Number of points nReached in unfold graph: %d\n',nReached);
  error('Unconnected subgraph.  Choose new unfList');
else
  fprintf('Graph is connected\n');
end

return;
