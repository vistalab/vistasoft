function [coords, layers] = CreateGrayDisk(gray, startPoint, radius);

global vANATOMYPATH;
mmPerPix = readVolAnatHeader(vANATOMYPATH);

% Find start point in the grayNodes
% Look first in allLeftNodes, then in allRightNodes
startNode = ...
    find(gray.nodes(2, :) == startPoint(1) & ...
    gray.nodes(1, :) == startPoint(2) & ...
    gray.nodes(3, :) == startPoint(3));
if isempty(startNode)
  coords = [];
  layers = [];
  return
end    

% Compute distances
distances = mrManDist(gray.nodes, gray.edges, startNode, mmPerPix, -1, radius);
diskIndices = find(distances >= 0);

% Coords in the gray matter
coords = gray.nodes([2 1 3], diskIndices);
layers = gray.nodes(6, diskIndices);

return