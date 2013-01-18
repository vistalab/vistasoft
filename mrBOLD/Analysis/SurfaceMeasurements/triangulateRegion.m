 function tri = triangulateRegion(x, y, regionX, regionY)
%
% triangles = triangulateRegion(x, y, regionX, regionY)
%
% AUTHOR:  Dougherty
% DATE:    09.20.99
% PURPOSE:
%
% Triangulates the verticies in x,y with triangles 
% constrained to fall within the region defined by
% the region specified by regionX, regionY.
% 
% This routine is basically an enhancement to delaunay
% (which it calls to set up the initial triangulation)
% in that it can produce the desired result for non-convex
% regions. 
%
% The region specification is basically just a list of
% points on the grid (eg. a set of ROI coords).
%

% get the full triangulation
tri = delaunay(x, y);

%
% Pare away triangles that have edges which are too far
% from the specified region.  We do this by finding the 
% midpoint of each edge.  If there isn't a region
% point at the floor or ceil of the midpoint, then delete that
% triangle.

for ii=1:length(tri)
	edgesX = [[x(tri(ii,1));x(tri(ii,2))],[x(tri(ii,2));x(tri(ii,3))],[x(tri(ii,3));x(tri(ii,1))]];
	edgesY = [[y(tri(ii,1));y(tri(ii,2))],[y(tri(ii,2));y(tri(ii,3))],[y(tri(ii,3));y(tri(ii,1))]];
	midX = [edgesX(1,:)-(edgesX(1,:)-edgesX(2,:))./2];
	midY = [edgesY(1,:)-(edgesY(1,:)-edgesY(2,:))./2];
   for jj=1:3
      ceilX = ceil(midX(jj))==regionX;
      ceilY = ceil(midY(jj))==regionY;
      floorX = floor(midX(jj))==regionX;
      floorY = floor(midY(jj))==regionY;
	   if ~(any(ceilX&ceilY)|any(ceilX&floorY)|any(floorX&ceilY)|any(floorX&floorY))
			% keep only the good ones by marking the bad ones for deletion
			tri(ii,:) = [nan nan nan];
      end
   end
end
tri(find(isnan(tri(:,1))),:) = [];

return

% for debugging
figure;
patch([x(tri(:,1)');x(tri(:,2)');x(tri(:,3)')], ...
   		[y(tri(:,1)');y(tri(:,2)');y(tri(:,3)')],'g');
hold on;
plot(regionX,regionY,'ok');
hold off;

% an algorithm for deleting triangles with edges that are too long:
edgeLen = [sqrt((x(tri(:,1))-x(tri(:,2))).^2+(y(tri(:,1))-y(tri(:,2))).^2);...
         sqrt((x(tri(:,2))-x(tri(:,3))).^2+(y(tri(:,2))-y(tri(:,3))).^2);...
         sqrt((x(tri(:,3))-x(tri(:,1))).^2+(y(tri(:,3))-y(tri(:,1))).^2)];
% Empirically, tooLong = 6 seems to work well.
tooLong = 6; 
for ii=1:length(tri)
   if any(edgeLen(:,ii)>=tooLong)
      % keep only the good ones by marking the bad ones for deletion
      tri(ii,:) = [nan nan nan];
   end
end