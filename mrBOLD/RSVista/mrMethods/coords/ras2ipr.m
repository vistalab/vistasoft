function iprXform = ras2ipr(rasXform,dims,voxelSize);
% Convert an Xform from R|A|S coordinates to I|P|R coordinates
%
% Usage:
% iprXform = ras2ipr(rasXform,dims);
%
% each xform is a 4x4 affine transformation matrix. This code
% does a set of flips and rotations about the center of a volume to
% exchange between spaces. dims is a 3-vector specifying the
% size in voxels of the xformed volume.
% 
% dims is the size of the data matrix to be transformed. This is used
% to ensure that rotations act about the center of the volume, rather
% than the corner. It is in units of (voxels per row, voxels per column,
% voxels per slice).
%
% voxelSize is the size of each voxel in mm. If omitted it defaults to 
% 1. This will only affect whether the transformed volume is centered 
% at (0,0,0) or not.
%
% In R|A|S space, (rows,cols,slices) map to increasing (right, 
% anterior, superior), while in I|P|R they map to increasing
% (inferior, posterior, right) locations. A slice (rows over
% colums) in R|A|S is an axial slice with the brain pointing
% the the left of the image. A slice in I|P|R is a sagittal
% slice with the brain pointing left.
%
% ras, 07/05.
if notDefined('voxelSize'), voxelSize = [1 1 1]; end

% size check
if length(voxelSize)<3,
	error('Need at least 3 dimensions for voxel size.'); 
end
if length(dims)<3,
	error('Need at least 3 dimensions for dimensions.'); 
end

extent = dims(1:3) .* voxelSize(1:3);

iprXform = affineBuild(extent/2,[0 pi/2 0],[1 -1 -1]);

% these shifts rotate the coords about the center of the volume
shift = [eye(3) -1*dims([2 1 3])'./2; 0 0 0 1];
iprXform = inv(shift)*iprXform*shift;

iprXform = iprXform * rasXform;

return
