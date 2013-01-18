function [g2vMap, distSq] = mrmMapGrayToVertices(grayNodes, vertexCoords, mmPerVox, distThresh)
%
% g2vMap = mrmMapGrayToVertices(grayNodes,vertexCoords, mmPerVox)
%
% Finds a map between all gray nodes and the mesh vertices
% To see the coordinate of a mesh node nearest to a gray node, we
% can use
%    
%      initVertices(1:3,g2vMap(idx))
%
%
% HISTORY:
%  2004.03.26 ARW wade@ski.org. Based on RFD's routine mrmVerticesToGray
if notDefined('mmPerVox'), error('Voxel size (mm per vox) is required.'); end;

if notDefined('distThresh')
    if (ispref('VISTA','defaultSurfaceWMMapDist'))
        distThresh = getpref('VISTA','defaultSurfaceWMMapDist');
	else
		if prefsVerboseCheck>=1,
	       disp('No dist threhold preference set. Setting distance threshold to 2 by default');
		end
		distThresh=2;
    end
    
end

% The gray coordinates are in voxels in the vAnatomy file.  This scales
% them into real physical (mm) coordinates.  And transposes them.
grayCoords = grayNodes([1,2,3], :);
grayCoords = [grayCoords(1,:).*mmPerVox(1); ...
        grayCoords(2,:).*mmPerVox(2); ...
        grayCoords(3,:).*mmPerVox(3) ]';

% Transposes these mesh coordinates, which were already built in real
% physical coordinates.  
% Major comments needed here.
vertexCoords = vertexCoords' + 1;

[g2vMap,distSq]=nearpoints(double(grayCoords'),vertexCoords');
badPoints=find(distSq>(distThresh.^2));
g2vMap(badPoints)=0;

g2vMap = int32(g2vMap);

return;
