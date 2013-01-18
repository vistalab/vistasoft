function [idx,eachDistance,errorValue] = flatFindPointDistances(ptsIndex,distances,gridPoints)
%Find the mesh point whose separation from the gridPoints matches the
%profile in distances
%
%  [idx,eachDistance,errorValue] = flatFindPointDistances(ptsIndex,distances,gridPoints)
%
%   Find the index of a point in the mesh whose distance from the points in
%   ptsIndex matches as well as possible the list in the variable
%   distances.  The list in distances specifies the profile for a point at
%   grid point G1 with respect to another grid point, G2.
%
%   This procedure lets us figure out which mesh points should be added to
%   a grid of positions.
%
%   Usually ptsIndex = 1 is the origin, ptsIndex= 2 is on the x-axis and
%   ptsIndex= 3 is on the y-axis.  The other points are grid points at
%   various locations. We call this routine to find grid point N, whose
%   distance from the other grid points is specified by the properties of a
%   perfect grid.
%
% Example:
%
% ptsIndex = [1,2]                                  % These are the origin and a point at (mxDist,0).
% distances = [mxDist,sqrt(mxDist^2 + mxDist^2)];   % Find a point at(0,mxDist)
% [yccordIDX,err] = flatFindPointDistances(ptsIndex,distances,gridPoints)
%
%Author: Wandell

% These are the indices into the grid points.
nPoints = length(ptsIndex);

% Get the distances from the grid points to other points from the structure
for ii=1:nPoints, dist(:,ii) = gridPoints(ii).dist; end

% We are going to cumulate the error across all of the grid points
err = zeros(size(dist(:,1)));
for ii = 1:nPoints
    err = (dist(:,ii) - distances(ii)).^2 + err;
end

% Measure the mean distance error.  We don't need to divide by nPoints, but
% we do because we may care about the typical error later.
err = sqrt(err/nPoints);

% Now, we choose the point (idx) whose distance profile is best.
[errorValue,idx] = min(err(:));
eachDistance = dist(idx,:);

return;
