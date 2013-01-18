function [newNodes,newEdges,nNotReached] = ...
   keepNodes(nodes,edges,keepList,verbose);
%
% [newNodes,newEdges,nNotReached] = keepNodes(nodes,edges,keepList,[verbose]);
%
% AUTHOR: SJC - 05.14.98
%         Based on Yung-Hsiang Lu's C++ function 'keepLayer'
% PURPOSE:	Adjust a graph structure by keeping only some of the
%		nodes.  You should check whether these nodes constitute
%		a connected graph.  See removeNodes for an
%		alternative form of this function.
% ARGUMENTS:
%	nodes:		Gray node matrix
%	edges:		Gray edge vector
%	keepList:	Columns in node matrix that should be kept.
%  verbose:		If 1, or not specified, messages will be displayed.
%					If 0, no messages will be displayed.
% RETURNS:
%	newNodes:	Data for the new graph, with the nodes removed
%	newEdges:	Data for the new graph, with the edges removed
%	nNotReached:	number of nodes not connected to any others.
%
% MODIFICATIONS:
% 09.02.98 SJC	Modified treatment of edges so that it can handle the case
%		when edges has two rows.
% 09.18.98 SJC	Fixed bug leftover from above modification.
% 10.16.98 SJC  Fixed function to handle cases when keepList only contains
%		one element.
%		Added the output argument nNotReached.
% 06.04.99 SJC, BW Added verbose option.
% 06.14.99 SJC Clear some variables to avoid running out of memory
%

if ~exist('verbose','var')
   verbose = 1;
end

if(length(keepList)==0)
  newNodes = [];
  newEdges = [];
  nNotReached = 0;
  if(verbose)
      disp([mfilename,': WARNING- keepList is empty...']);
  end
  return;
end
      
% New list of nodes
newNodes = nodes(:,keepList);

if (length(keepList) > 1)
  % Get the dimension of the edges array
  dimEdges = size(edges,1);

  % Create index mapping of all previous nodes:
  %   nodes that are kept get reindexed to their new positions on the nodes list
  %   nodes that are to be removed are marked by a -1
  indexMap = -1*ones(1,size(nodes,2));
  indexMap(keepList) = [1:length(keepList)];

  % Map all the nodes in the original edges list with the index map created above
  edgesMap = indexMap(edges(1,:));

  % Initialize newEdges to its maximum size.  Most probably too big, but it will
  % be resized at the end
  newEdges = -ones(size(edges));

  % Index for newNodes
  ii = 1;
  % Initialize index into newEdges
  newNodes(5,ii) = 1;

  for jj = 1:length(keepList)
    clear currEdges
  
    % Indices into the edges list of connections to current node
    kk = nodes(5,keepList(jj));
    edgesIdx = [kk : kk + nodes(4,keepList(jj)) - 1];
  
    % List of other nodes current node is connected to
    if ~isempty(edgesIdx)
      currEdges(1,:) = edgesMap(edgesIdx);
      if (dimEdges == 2)
        currEdges(2,:) = edges(2,edgesIdx);
      end
  
      % Find the nodes that have not been removed
      keepIdx = find(currEdges(1,:) > 0);
  
      % Count how many nodes the current node is still connected to (after removal)
      newNodes(4,ii) = length(keepIdx);

      % Recalculate the next node's index into the edges list
      newNodes(5,ii+1) = newNodes(5,ii) + newNodes(4,ii);

      % These will be the edges of the current node
      ll = newNodes(5,ii);
      newEdgesIdx = [ll : ll + newNodes(4,ii) - 1];
      newEdges(:,newEdgesIdx) = currEdges(:,keepIdx);

    else
      newNodes(4,ii) = 0;
      newNodes(5,ii+1) = newNodes(5,ii);
    end
          
    ii = ii + 1;
  end
  
  clear nodes
  clear edges
  clear edgesMap
  clear indexMap

  % Eliminate last node (bogus node, contains no data)
  newNodes(:,length(keepList) + 1) = [];

  % Eliminate all extraneously allocated edges
  removeIdx = find(newEdges(1,:) == -1);
  newEdges(:,removeIdx) = [];

  % Find number of nodes that are not connected to any others
  idx = find(newNodes(4,:) == 0);
  unconnectedCount = length(idx);
  if (unconnectedCount > 0)
     nNotReached = unconnectedCount;
     if verbose
        fprintf('There are %d unconnected points.\n', unconnectedCount);
     end
  else
     nNotReached = 0;
  end
  
else
  % keepList contains only one element, so that node will not be
  % connected to any others.
  %
  newNodes(4) = 0;
  newNodes(5) = 0;
  newEdges = [];
  nNotReached = 0;
end

return
