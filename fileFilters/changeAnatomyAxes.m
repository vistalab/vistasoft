function [volOut,axisLabels]=changeAnatomyAxes(inVolume,axisTransform)
% function [volOut,axisLabels]=changeAnatomyAxes(inVolume,axisLabels)
% Rearrange the axes of a medical imaging brain volume.
% INPUT:
% inVolume:          3D input volume. 
% axisTransform: This defines the way the axes will be re-arranged.
%              : It is a 3*1 array which must contain a permutation of the digits [1,2,3]
% Basically, we call 'permute' with this array (after doing some flips).

% Example: 
% We have a volume y*x*z in size (so size(inVolume)=[y,x,z]
% The axes are y: axial, x: coronal, z: sagittal.
% In other words, if we take an image slice a=inVolume(:,:,fix(z/2));
% then 'a' is a sagittal view of the midline with the nose facing left, and dorsal pointing up.
% Now we want to rearrange the volume so that the same slice (:,:,fix(z/2)) will give us an axial view with the
% nose pointing up and the right ear on the right: y coronal, x sagittal, z axial
% So axisTransform is
% [2 3 1]
% In other words, the first axis in the original image becomes the 3rd axis in the target
% The second axis becomes the first and the third becomes the second.
% To flip the image so that left and right ears were reversed, we would make the second entry -ve: [2 -3 1]



% ARW 03.12.02

% Check number of input argumnents and size of inVolume

if (nargin~=2)
    error('This routine needs 2 input arguments');
end

volSize=size(inVolume);


axisTransform=axisTransform(:);

if (length(axisTransform)~=length(volSize))
    error('axisTransform matrix must be a vector with the same number of entries as there are dimensions in inVolume');
end


% Do flipdim operations 
[flippedDims]=find(axisTransform<0);

for t=flippedDims
    flipdim(inVolume,abs(axisTransform(t)));
end

% Do the permutation
volOut=permute(inVolume,abs(axisTransform));

