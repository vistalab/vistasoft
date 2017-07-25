function [anat, inplanes] = ReduceFOV(anat, inplanes, fovRatio)
% Resamples the inplane anatomy images to reduce their FOV
%
%   [anat, inplanes] = ReduceFOV(anat, inplanes, fovRatio);
%
% The purpose of this routine is to match the anatomical FOV to the
% functional images. The input fovRatio is a 2-element vector that provides
% the FOV reduction as a rational fraction, e.g., to reduce the FOV from 15
% cm to 10 cm, fovRatio = [2, 3]. This method provides precise FOV
% adjustment only when anat contains images with even inplane dimensions.
%
% This process could be done more automatically - RFD
% 
% Ress, 9/1/03

% Argument checking goes here

%
s = size(anat);
nIm = s(3);
nxy = s(1:2);
nxyU = nxy * fovRatio(2);
nxyD = nxy * fovRatio(1);
ixy1 = (nxyU - nxyD)/2 + 1;
ixy2 = ixy1 + nxyD - 1;
hh = mrvWaitbar(0, 'Reducing FOV...');

% Adjust the images:
for ii=1:nIm
  imU = imresize(anat(:, :, ii), fovRatio(2), 'bicubic');
  imD = imU(ixy1(1):ixy2(1), ixy1(2):ixy2(2));
  anat(:, :, ii) = imresize(imD, 1/fovRatio(1));
  mrvWaitbar(ii/nIm, hh);
end

% Adjust the inplanes structure:
rat = fovRatio(1)/fovRatio(2);
inplanes.original.FOV = inplanes.FOV;
inplanes.original.voxelSize = inplanes.voxelSize;
inplanes.FOV = inplanes.FOV * rat;
inplanes.voxelSize(1:2) = inplanes.voxelSize(1:2) * rat;
close(hh);

return;
