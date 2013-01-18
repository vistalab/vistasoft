function [IDX,err] = flatFindPointAtPosition(pos,gridPoints)
%
%    [IDX,err] = flatFindPointAtPosition(pos,gridPoints);
%
%  Find a mesh point that falls at a particular position, pos, with respect
%  to the current grid points.  
%
%  The structure gridPoints contains information about the grid points that
%  have already been mapped. Specifically, gridPoints(ii).loc is the grid
%  position of that point, and gridPoints(ii).dist are the manifold
%  distances from that point to all the other points in the current mesh.
%
% Example:
%
%  pos(1) = mxDist; pos(2) = mxDist;
%  [IDX,err] = flatFindPointAtPosition(pos,gridPoints);
%
% VISTASOFT, Stanford

pts = 1:length(gridPoints);
distances = zeros(1,length(pts));

for ii=1:length(pts)
    distances(ii) = norm(gridPoints(ii).loc - pos);
end

[IDX,eachDistance] = flatFindPointDistances(pts,distances,gridPoints);
err = norm(distances - eachDistance);

return;
