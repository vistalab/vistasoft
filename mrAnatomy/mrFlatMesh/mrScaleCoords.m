function coords = mrScaleCoords(coords, voxSize)
% 
% coords = mrScaleCoords(coords, voxSize)
%
% AUTHOR:  Maher Khoury 
% DATE:    08.20.99
% PURPOSE:
%	Scales the nodes coordinates by the voxel sizes
% 
% INPUT:
%	coords is a Nx3 matrix where N is the number of nodes
% 	voxSize is a 1x3 matrix usually found in mesh.parameters.structural
%   
% SEE ALSO:  MrReadMrM
%
% Notes:  
coords(:,1) = coords(:,1) / voxSize(1);
coords(:,2) = coords(:,2) / voxSize(2);
coords(:,3) = coords(:,3) / voxSize(3);

return