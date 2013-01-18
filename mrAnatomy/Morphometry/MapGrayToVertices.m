function [g2vMap, dMap] = MapGrayToVertices(grayNodes,vertexCoords, mmPerVox)
%
% g2vMap = mrmMapGrayToVertices(grayNodes,vertexCoords, mmPerVox)
%
% Finds a map between the input gray nodes and the input mesh vertices
% using the nearpoints routine.
%
% Rewritten from Bob Dougherty's mrmMapVerticesToGray

if ieNotDefined('mmPerVox'), error('Voxel size (mm per vox) is required.'); end;

% The gray coordinates are in voxels in the vAnatomy file.  This scales
% them into real physical (mm) coordinates.  And transposes them.
grayCoords = grayNodes([1,2,3], :);
grayCoords = [grayCoords(1,:).*mmPerVox(1); ...
        grayCoords(2,:).*mmPerVox(2); ...
        grayCoords(3,:).*mmPerVox(3) ]';

% Transposes these mesh coordinates, which were already built in real
% physical coordinates.  
vertexCoords = vertexCoords' + 1;

[g2vMap, sqDist] = nearpoints(grayCoords', vertexCoords');
dMap = sqrt(sqDist);

g2vMap = int32(g2vMap);

return;
