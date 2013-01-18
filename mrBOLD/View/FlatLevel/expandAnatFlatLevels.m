function flat = expandAnatFlatLevels(flat);
%
% flat = expandAnatFlatLevels(flat);
%
% replicates the anat image to have a number of slices,
% corresponding to each flat level
%
% TO DO: technically, the curvature of a flattening
% ought to change with distance from the gray/white
% surface. It would be cool, but by no means essential,
% to have the curvature map for each level reflect this.
%
% 09/04 ras.

% get # of levels from numLevels field
% (created in buildFlatLevelCoords)
numLeftLevels = flat.numLevels(1);
numRightLevels = flat.numLevels(2);

% replicate for the appropriate number of R/L levels
leftRng = 3:numLeftLevels+2;
flat.anat(:,:,leftRng) = repmat(flat.anat(:,:,1),[1 1 numLeftLevels]);
rightRng = numLeftLevels+3:numLeftLevels+numRightLevels+2;
flat.anat(:,:,rightRng) = repmat(flat.anat(:,:,2),[1 1 numRightLevels]);

% initialize the flat rotations -- does it for 2 slices
[rotations,flipLR] = getFlatRotations(flat); 
 
% also expand the flipLR + rotateImageDegrees fields
flat.flipLR = flipLR;
flat.flipLR(leftRng) = flipLR(1);
flat.flipLR(rightRng) = flipLR(2);
flat.rotateImageDegrees = rotations;
flat.rotateImageDegrees(leftRng) = flat.rotateImageDegrees(1);
flat.rotateImageDegrees(rightRng) = flat.rotateImageDegrees(2);

% flat = setFlatRotations(flat,rotations,flipLR);

return