function [nodes, edges] = Connections2Graph(uniqueSparse,vertices);
% 
%  [nodes, edges] = Connections2Graph(uniqueSparse,vertices);
% 
% AUTHOR:  MK/BW
% DATE:    09.06.99
% PURPOSE:
% 
%   Compute nodes and edges for gray graph data.  The graph is
% computed from the uniqueSparse matrix created in
% Mesh2GrayGraph, along with the mesh vertices (floats). 
% In this routine, the vertices are rounded to be integer
% valued "nodes."
% 
% TODO:
% 1.  Figure out which routines break if nodes are not integers.
% 
% Vertices must be integers in mrGray and other places.  But,
% the mesh falls on float values.  When we round, some of the
% mesh vertices that are close, fall on the same integer
% node.  This may not happen if we use cube faces.
% 
% Possibly, we should scale up the precision by 10 or so.
% Or, possibly, we can keep the precision. I am not sure what
% consequences this will have for mapping data from gLocs3d
% ...  Needs to be thought through.  Who breaks if nodes are
% not integers?
% 
% BW 09.05.99
% 

% Convert the mrGray format vertices to mrLoadRet format
% Perhaps the rounding has already happened, but that shouldn't
% matter.  If it is arounded by now, then this won't hurt.
% 
vertices = mrGray2mrLoadRet(round(vertices));

% The rounding now collapses some of the nodes to the same
% position.  What should we do to remove the case of multiple
% nodes at the same position?
% 
% One possibility is to keep them all, say by scaling the
% positions by 10 and holding things as integers.  Another
% possibility is to collapse the vertices once more and combine
% their connections
% 
disp('Connections2Graph isn't right yet.');

% NEW numNodes
% 
numNodes = size(uniqueSparse,1);

nodes = zeros(8,numNodes);
nodes(1,:) = vertices(:,1)';
nodes(2,:) = vertices(:,2)';
nodes(3,:) = vertices(:,3)';
nodes(4,:) = full(sum(uniqueSparse,2))';
nodes(5,:) = [0 cumsum(nodes(4,1:(numNodes-1)))] +1;
nodes(6,:) = ones(1,numNodes);
%% 7,8 are junk.  No need to fill them.
   
% The edges are defined with Matlab uses numbering from 1 to N.
% 
% This code performs the conversion for all nodes all at once.
% We use the mod operation to find the column number.
% We first subtracting 1 and then mod by numNodes.  This produces
% a column number that runs between ([0,numNodes-1]).  We add 1
% to get back to Matlab numbering. 
% 
edges = mod((find(uniqueSparse)-1),numNodes)+1; 

% keepNodes, and other mrGray functions want the edges to be a
% row, not a column.
% 
edges = edges(:)';

return;

