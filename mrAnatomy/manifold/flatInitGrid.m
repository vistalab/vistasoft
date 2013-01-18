function [gridPoints,mxDist] = flatInitGrid(D,startNodeIdx,maxFractionDist)
% Initialize (0,0) and (X,0) to build up the cartesian grid
%
%   [gridPoints,mxDist]  = flatInitGrid(D,startNodeIdx)
%
% Author: Wandell
%    We currently pick the x-axis as a distant point and assign it the
%    coordinate (X,0) where X is its distance from the start. 
%
%    In the future, we will use the GUI to identify the 3D location of the
%    X-Axis point. This will produce the xcoordIDX value below.
%

if ieNotDefined('maxFractionDist'), maxFractionDist = 0.8; end

%  These are the distances from the start node (0,0) to each of the other nodes.
gridPoints(1).loc = [0,0];
gridPoints(1).idx = startNodeIdx;
gridPoints(1).dist = dijkstra(D,startNodeIdx)';
gridPoints(1).err = 0;

mxDist = floor(max(gridPoints(1).dist)*maxFractionDist);

% Now, we need a mechanism for picking a node on the X-axis at a far
% distance, (X,0).  Ultimately, we will ask the user to pick a point and
% use that one. For now, we find a point (almost surely a perimeter point)
% near the max distance.
[v,xcoordIDX] = min(abs(gridPoints(1).dist - mxDist));
gridPoints(2).idx = xcoordIDX;
gridPoints(2).dist = dijkstra(D,xcoordIDX)';
gridPoints(2).loc = [gridPoints(2).dist(startNodeIdx),0];
gridPoints(2).err = 0;

return;