function [newLocs2d, idxGood] = flatAdjustSpacing(mesh,spacingMethod)
% Adjust the flat mesh spacing to equalize point density
%
%   [newLocs2d, idxGood] = flatAdjustSpacing(mesh,[spacingMethod = 'cartesian'])
%
% The first placement of the 2d locations by mrMeshFlat makes no effort
% to space the points according to their manifold distances (i.e.,
% distance measured along the surface of the brain).  This routine takes
% the initialize 2d positions and adjusts them, without introducing any
% folds, so that the new 2d distances are closer to the original 3D
% distances.
%
% The logic of the algorithm is this.  We place the start node at the
% origin and we choose another point on the X-axis.  We assign the second
% point the location (D,0) where X is the point's distance from the start
% node. We assign these points the locations (0,0) and (D,0) in the flat
% representation.
% 
% Then, we continue selecting points at grid locations.  Specifically, for
% a set of points at a  sample grid position, we find a gray matter point 
% whose distance matches the desired profile to the already defined points
% as closely as possible. 
% 
% For example, to find a point on the y-axis (0,D), we know that it's
% distance D from the start node  and a distance sqrt(2)*D from the x-axis
% point.  This point is assigned the flat location (0,D).  We then pick a
% next grid point to assign, say (D,D), and we find the mesh point whose
% distance profile matches the required one as closely as possible.
%
% We use this process to identify some number of points.  Usually 10-20
% grid points.  This part of the routine, identifying the grid points from
% a mesh, should be pulled out as a separate function.  This routine can
% work on any graph comprising nodes and edges by using Dijkstra's
% algorithm.
%
% For mrFlatMesh in particular, we need to assign a coordinate to all
% points, not just a sample of grid points. To assign the remaining points,
% we find the Delaunay triangulation of the grid points on their original
% mesh.  For each point, we find its triangle.  We assign the position of
% these non-grid points based on their distance from each of the points in
% the corners of their own Delaunay triangle.  This can be solved for
% uniquely.
%
% The newLocs2d are the positions of the adjusted points. During this
% process, some of the flattened points are left out because they are at a
% boundary we can't deal with.  The indices of the ones that have been are
% indicated in the logical variable idxGood.  Thus, original mesh,
% mesh.locs2d(idxGood,:) contains the original positions. newLocs2d
% contains the new positions.
%
% Example:
%  Get mesh from a flat.mat file
%  [newLocs2d, idxGood] = flatMakeGrid(mesh)
%
% VISTASOFT, Stanford (wandell)

% Test with small flat map.
% 
% clx
% chdir('G:\anatomy\donoho\classprojects\left\unfold');
% load test 
% mesh   = unfoldMeshSummary;
% locs2d = mesh.locs2d;
% figure; plot(locs2d(:,1),locs2d(:,2),'k.'); axis equal

% Parameter checking on the mesh input
%
if ieNotDefined('mesh'), error('You must pass in a mesh structure from a flat file.'); end
if ieNotDefined('spacingMethod'), spacingMethod = 'cartesian'; end

if checkfields(mesh,'locs2d'), locs2d = mesh.locs2d; 
else error('mesh must have locs2d field.'); end

if checkfields(mesh,'maxFractionDist'), maxFractionDist = mesh.maxFractionDist; 
else maxFractionDist = 0.8; end

if checkfields(mesh,'gridSpacing'), gridSpacing = mesh.gridSpacing; 
else gridSpacing = 0.5; end

% Original 2d positions in mrFlatMesh.

startNodeIdx = flatFindStartNodeIndex(mesh);

% Build the connection matrix.
% Scale factor describes the spacing in each of the dimensions   
D = sqrt(find3DNeighbourDists(mesh,mesh.scaleFactor)); 

%  Create points (at least origin and x-axis) to initiate thep placement we
%  of the grid points.
[gridStart, mxDist] = flatInitGrid(D,startNodeIdx,maxFractionDist);

%  Build the positions we want to target for the grid
pos = flatBuildGrid(spacingMethod,gridSpacing,mxDist);
% angSpacing = 0.7854; distSpacing = 0.4; pos = flatBuildGrid('polar',angSpacing,distSpacing, mxDist);

% We now have enough information to specify additional grid positions
gridPoints = flatAddGridPoints(pos,D,gridStart);
gridPoints = flatAdjustGridPoints(pos,D,gridPoints);

idx = flatGetGrid(gridPoints,'idx');
if length(idx) ~= length(unique(idx)), error('Same point picked twice.'); end
% flatPlotGridPointSequence(gridPoints,pos,locs2d,mxDist)

from = locs2d(idx,:);
to = flatGetGrid(gridPoints,'loc');

% This builds up,  point by point, a graph of the locs2d and the corresponding grid
% points. We might find the best rotation to align them before carrying on.
% figure(100);
% clf
% for ii=1:length(to)
%     plot(from(ii,1),from(ii,2),'ko',to(ii,1),to(ii,2),'ks');
%     set(gca,'xlim',[-15,15],'ylim',[-15,15]); axis equal
%     hold on;
%     plot(from(ii,1),from(ii,2),'bo',to(ii,1),to(ii,2),'rs');
%     set(gca,'xlim',[-15,15],'ylim',[-15,15]); axis equal
%     hold on;
%     pause(0.3)
% end

% Could check for degeneracy
% TRI1 = delaunay(from(:,1),from(:,2));

gridTesselation = delaunay(to(:,1),to(:,2));

% clf; 
% figure(1); 
% trisurf(gridTesselation,from(:,1),from(:,2),ones(size(from(:,1))),1:length(from(:,1))); axis equal
% colormap(redgreencmap(0,length(to(:,1))));
% 
% figure(2);
% clf; 
% trisurf(gridTesselation,to(:,1),to(:,2),ones(size(to(:,1))),1:length(to(:,1))); axis equal
% colormap(redgreencmap(0,length(to(:,1))));
% colorbar('horiz')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% For each triangle, find the affine map such that
% fromPts*T = toPts
% The columns of fromPts are [X,Y,1]
% The columns of toPts are [X,Y]
%
% Every point inside the triangle, T, will be mapped from its current value
% to its position in the uniform grid by from*T = to

nTriangles = size(gridTesselation,1);
for ii=1:nTriangles
    fromPts = from(gridTesselation(ii,:),:);
    toPts = to(gridTesselation(ii,:),:);
    fromPts = [fromPts,ones(3,1)];
    T{ii} = fromPts\toPts;
end

% For every point in the flat representation locs2d, we need to figure out
% which triangle it falls in.  We use tsearch
%
whichT = tsearch(from(:,1),from(:,2),gridTesselation,locs2d(:,1),locs2d(:,2));

% Make a plot showing how many points in each of the triangles.
figure; hist(whichT(:),round(length(whichT)/30)); 
title('No., points in each triangle (should be roughly even)')

newLocs2d = zeros(size(locs2d));

for ii=1:nTriangles
    l = (whichT == ii);
    old = locs2d(l,:);
    old = [old , ones(size(old,1),1)];
    new = old*T{ii};
    newLocs2d(l,:) = new;
end

idxGood = ~isnan(whichT);
newLocs2d = newLocs2d(idxGood,:);

figure;
subplot(1,2,1)
triplot(gridTesselation,from(:,1),from(:,2),'r--'); axis equal
hold on; plot(locs2d(:,1),locs2d(:,2),'k.'); hold off

subplot(1,2,2)
triplot(gridTesselation,to(:,1),to(:,2),'r--'); axis equal
hold on; plot(newLocs2d(:,1),newLocs2d(:,2),'k.'); hold off


return;
