function newGridPoints = flatAddGridPoints(pos,D,gridStart)
%Add points to a grid used for flattening
%
%   newGridPoints = flatAddGridPoints(pos,D,gridStart)
%
%   Using the connection matrix, D, and the initialized points in
%   gridStart, find the best bet for all the new positions in pos.
%
%   The method builds up the grid by setting a few points and then finding
%   the next point that matches the distance requirements as well as
%   possible to all of the previous points
%
% Author: Wandell

if ieNotDefined('gridStart'), 
    error('You must set an initial set of grid points.  See flatInitGrid.'); 
end

nStartPoints = length(gridStart);
currentGridPoints = gridStart;

for ii=1:length(pos)
    [idx,err] = flatFindPointAtPosition([pos(ii,1),pos(ii,2)],currentGridPoints);
    
    newGridPoints(ii).loc = [pos(ii,1),pos(ii,2)];
    newGridPoints(ii).idx = idx;
    newGridPoints(ii).dist = dijkstra(D,idx)';
    newGridPoints(ii).err = err;
    currentGridPoints(ii + nStartPoints) = newGridPoints(ii);

end

return;