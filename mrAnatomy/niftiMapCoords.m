function targetVoxel = niftiMapCoords(sourceNifti, sourceVoxel, targetNifti)
% niftiMapCoords - Map voxel coordinates between two NIfTI images
%
%   targetVoxel = niftiMapCoords(sourceNifti, sourceVoxel, targetNifti)
%
% Maps a voxel coordinate from one NIfTI image to the corresponding
% location in another NIfTI image using their affine transforms.
%
% Inputs:
%   sourceNifti  - NIfTI struct (from niftiRead) containing the source voxel
%   sourceVoxel  - [row, col, slice] or [row, col] voxel coordinates (1-indexed)
%   targetNifti  - NIfTI struct to map coordinates into
%
% Output:
%   targetVoxel  - [row, col, slice] coordinates in target image (1-indexed)
%                  Returns fractional values; use round() for display
%
% Example:
%   % Find high-res voxel corresponding to BOLD voxel [40, 15, 10]
%   hrVoxel = niftiMapCoords(boldData, [40, 15, 10], highResAnat);
%   hrSlice = round(hrVoxel(3));
%   hrRow = round(hrVoxel(1));
%   hrCol = round(hrVoxel(2));
%
% See also: niftiRead, niftiView

% Handle 2D input (assume slice = 1)
if numel(sourceVoxel) == 2
    sourceVoxel = [sourceVoxel(:); 1];
end

% Get affine transforms (voxel to physical coordinates in mm)
% NIfTI uses 0-indexed voxels, so we subtract 1 before transform
sourceAffine = sourceNifti.qto_xyz;
targetAffine = targetNifti.qto_xyz;

% Convert source voxel to physical coordinates (mm)
% NIfTI convention: 0-indexed, so subtract 1
sourceVoxel0 = [sourceVoxel(:) - 1; 1];  % homogeneous coordinates, 0-indexed
physicalCoord = sourceAffine * sourceVoxel0;

% Convert physical coordinates to target voxel
% Invert target affine and apply
targetAffineInv = inv(targetAffine);
targetVoxel0 = targetAffineInv * physicalCoord;

% Convert back to 1-indexed MATLAB convention
targetVoxel = targetVoxel0(1:3)' + 1;

end
