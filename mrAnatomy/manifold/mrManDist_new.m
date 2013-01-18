function dist=mrManDist_new(nodeList,edgeList,startNode,dimDist,noval,radius)
% function [dist,pathIndices]=mrManDist_new(nodeList,edgeList,startNode,dimdist,-1,0)
%
% Obsolete, I think (BW)
%
%% ARW 031201
% This is a wrapper to replace mrManDist with the dijkstra routine from Stanford University
% mrManDist seems to be broken in some way. It certainly doesn't work with small floats
% This is the sort of thing you had to do to call mrManDist....	
% [nodeList, edgeList]=generateManDistNodes(mesh);
% mesh.dist = mrManDist(nodeList,edgeList,startNode,dimdist,-1,0); 
% dimdist is a scale factor for each linear dimension
% -1 is what's returned for a node with no connection to the start node.
% 0 says we're not sending in a list of node distances
% Edgelist is a 2xn list of node pairs
% Nodelist is a list of 3d node positions.

% To call dijkstra we need to make a weighted sparse connection matrix
% With each entry being the distance between the relevent nodes

disp('mrManDist_new is Obsolete. If you think it is necessary, please rename it and fix mrManDist.')
evalin('caller','mfilename')

return;

mesh.connectionMatrix = buildConnectionMatrix(nodeList, edgeList);

% Get rid of all the extra rubbish
mesh.uniqueVertices = nodeList(1:3,:)';

D = find3DNeighbourDists(mesh,dimDist);
dist = dijkstra(D,startNode);
dist = sqrt(dist);

return;