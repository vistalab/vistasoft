function [keepList,nodes,edges] = ...
    selectGrayDisk(nodes,edges,startNode,dimdist,radius)
% 
% [keepList nodes edges] = selectGrayDisk(nodes,edges,startNode,dimdist,radius)
% 
% AUTHOR: Wandell
% DATE:   03.19.98
% PURPOSE:
%    Find the indices within a given radius of a start point.
% 
% ARGUMENTS:
%   nodes,edges:  from gray graph
%   startNode:
%   dimdist:      from Unfoldparams
%   radius:       radius of the disk

% DEBUG:
% radius = 50;
% startNode = round(size(nodes,2)/4);

[dist nPntsReached] = mrManDist(nodes,edges,startNode,dimdist,-1,radius);
keepList = find(dist >= 0);

if nargout == 3
  disp('selectGrayDisk:  Creating new set of nodes and edges');
  [nodes edges] = keepNodes(nodes,edges,keepList);
end

return;
