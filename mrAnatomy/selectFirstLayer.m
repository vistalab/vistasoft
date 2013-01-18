function [keepList, nodes,edges] = selectFirstLayer(nodes,edges)
% 
% [keepList, nodes,edges] = selectFirstLayer(nodes,edges)
% 
% AUTHOR:  Wandell
% DATE:    03.20.98
% PURPOSE:
%   Identify the first layer points.  If three arguments, then
% keepNodes is run and the new nodes and edges of the first layer
% portion are returned.
% 
% ARGUMENTS:
%   nodes, edges:  gray graph
% 
% RETURNS:
% 
%  keepList:  Index of first layer
%  nodes, edges:  New nodes and edges of first layer points
% 

keepList = find(nodes(6,:)  == 1);

if nargout == 3
  disp('selectFirstLayer:  computing new nodes and edges');
  [nodes edges] = keepNodes(nodes,edges,keepList);
end

return;


