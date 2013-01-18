function [volOut,axisLabels]=changeAnatomyAxes(inVolume,axisTransform)
% function [volOut,axisLabels]=changeAnatomyAxes(inVolume,axisLabels)
% Rearrange the axes of a medical imaging brain volume.
% INPUT:
% inVolume:          3D input volume. 
% axisTransform: This defines the way the axes will be re-arranged.
%              : It is a 3x3 matrix. Each row and column has exactly 1 non-zero entry (==[1 | -1])
%              : The location (p = 1,2,3) of the 1 or -1 in each row indicates the index of that dimension in the re-arranged volume.
%              : a negative sign indicates that the dimension is to be flipped.
% if axisTransform is a 3x3 identity matrix, there is no rearrangenent.
% Example: 
% We have a volume y*x*z in size (so size(inVolume)=[y,x,z]
% The axes are y: axial, x: coronal, z: sagittal.
% In other words, if we take an image slice a=inVolume(:,:,fix(z/2));
% then 'a' is a sagittal view of the midline with the nose facing left, and dorsal pointing up.
% Now we want to rearrange the volume so that the same slice (:,:,fix(z/2)) will give us an axial view with the
% nose pointing up and the right ear on the right: y coronal, x sagittal, z axial
% So transform axis is
% 0 0 1
% 1 0 0
% 0 1 0 
% In other words (reading row-wise): the first axis in the original image becomes the 3rd axis in the target
% The second axis becomes the first and the third becomes the second.
% To flip the image so that left and right ears were reversed, we would make the third row [0 -1 0]



% ARW 03.12.02

% Check number of input argumnents and size of inVolume

if (nargin~=3)
    error('This routine needs 3 input arguments');
end

volSize=size(inVolume);

if (length(volSize~=3)
    error('Input volume must be 3D');
end

if (unique(size(axisTransform))~=3)
    error('Transform matrix must be 3x3');
end



% Do flipdim operations 
[flippedDims,dummy]=find(axisTransform<0);

for t=flippedDims
    flipdim(inVolume,t);
end

% Generate the info for 'permute'
[permOrder,dummy]=find(abs(axisTransform));

volOut=permute(inVolume,permOrder);

