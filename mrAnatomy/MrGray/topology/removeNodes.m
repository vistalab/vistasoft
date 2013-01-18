function [newNodes, newEdges] = removeNodes(nodes,edges,removeList)
% 
% [newNodes, newEdges] = removeNodes(nodes,edges,removeList)
% 
%AUTHOR:  Wandell, Heeger
%DATE:  03.25.97
% 
%PURPOSE:  Adjust a graph structure by removing some of the
% nodes.  You should check whether removing these nodes leaves
% you with one connected graph.
% 
%ARGUMENTS:
% 
% nodes:       Gray node matrix
% edges:       Gray edge vector
% removeList:  Indices of columns in node matrix that should be removed.
% 
% RETURNS:
% 
% newNodes:  Data for the new graph, with the nodes removed
% newEdges:  Data for the new graph, with the edges removed
%    The new edges refer to the node number in the new graph, we
% think, as they should. 
% 
% NOTES:
% We do not confirm every time whether the resulting graph is
% symmetrically connected.  We did this during testing, though (
% see test code at the bottom of the routine).  You might try
% this yourself from time to time.
%
% MODIFICATIONS:
%
% 11.03.98 SJC	Updated removeNodes to call keepNodes so there is
%		only one key algorithm that needs to be kept up to
%		date.  (Old code is in /old subdirectory.)
%	  NOTE: The resulting graph is now guaranteed to be 
%		symmetric, but is only guaranteed to be continuous
%		if the nodes in the removeList form a continuous
%		graph.  You might want to use checkGrayContinuity 
%		to make sure the graph is continuous.
%

if nargin < 3
  error('removeNodes requires three input arguments')
end
if isempty(removeList) %14/12/97 aiw updated for v5 == []
  return;
end

% Figure out index (column of nodes) of each node that we plan to keep
% 
keepList = 1:size(nodes,2);
keepList(removeList) = [];

% Call keepNodes so that only the nodes on the keepIndex are kept
%
[newNodes newEdges] = keepNodes(nodes,edges,keepList);

return;

% 
% Debugging code
% 
% cd /usr/local/matlab/toolbox/stanford/mri/unfold/Example
% [nodes edges] = readGrayGraph('Graph.gray');
% removeList = find(nodes(6,:) > 1);

% [nodes1 edges1] =  removeNodes(nodes,edges,removeList);

% plot(edges);
% plot(edges1);

% The offset is 5, the num of edges is 4.  So, it should always
% be the case that the previous offset plus num of edges should
% equal the next offset
% 
% err = ones(1,length(nodes1(5,:))-1);
% for i=2:size(nodes1,2)
%   err = nodes1(5,i) - (nodes1(5,(i-1)) + nodes1(4,(i-1)));
% end
% max(err)


% If node i is connected to node j, then node j must be connected
% back to i.  So, we check this in the new nodes and edges
% returned by remove node code.
% 
% This routine returns the number of asymmetric nodes, and which
% ones they are is printed out.
% 
% nMissed = checkGraySymmetry(edges1,nodes1)


% Try removing a geodesic, like the one that would be a cut along
% the depth of the calcarine
% 
% 
% dimdist = [1.0667 1.0667 1.0000];
% radius = 30
% crit = 3
% seed1 = 100;
% spacing = 1;
% 
% lineIdx = mrGeodesic(nodes,edges,dimdist,radius,spacing,crit,seed1);
% [nodes1 edges1] =  removeNodes(nodes,edges,lineIdx);
% nMissed = checkGraySymmetry(edges1,nodes1)

return;
