function X_zero=assignPerimeterPositions(radius,mesh); 
% Define a set of perimeter points on the circle.
%
%   X_zero=assignPerimeterPositions(perimeterDists,mesh); 
%
% orderMeshPerimeterPointsAll is the routine that gets the perimeter points
% into the proper order for the mapping here.   The mapping here simply
% puts these points on a circle.  In principle, we could put the points at
% these angles but adjust for distance.  In that case, however, we might
% not have a convex set.  So, we use a circle.
%
% The most anterior point in the sub mesh should map to the top of the
% circle. The most posterior point should be on the left or right.
%
% Stanford.

numPerimPoints=length(mesh.orderedUniquePerimeterPoints);

% Find the maximum y value in the perimeter
[maxHeight,maxHIndex]=max(mesh.uniqueVertices(mesh.orderedUniquePerimeterPoints,2));

angles=linspace(0,2*pi,numPerimPoints)';
angles=shift(angles(:),[-maxHIndex,0]);

X_zero=zeros(numPerimPoints,2);

% Perimeter must be convex for Tutte's algorithm  to work properly - 
X_zero(:,1)=radius.*cos(angles);
X_zero(:,2)=radius.*sin(angles);

return;
