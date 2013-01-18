function img_new = dtiResliceAnalyzeSn3d(img, sn3dParams, nonLinearFlag, mmPerVoxOut)
% img_new = dtiResliceAnalyzeSn3d(img, sn3dParams, [nonLinearFlag], [mmPerVoxOut])
% 
% Applies spm-style sn3d parameters to a volume loaded using loadAnalyze.
% These sn3d parameters include a linear (affine) component and a non-linear component.
%
% INPUT:
%   img                 XxYxZ image array.
%   sn3dParams          The sn3d parameter structure from SPM.
%   nonLinearFlag       If 1 (default), non-linear component is included.
%                       If 0, then non-linear component is not included.
%   mmPerVoxOut         mm per voxel in resliced array.
%
% OUTPUT:
%   img_new             XxYxZ image array.
%
% REQUIRES:
% spm99 or spm2 in the path.
%
% HISTORY:
% 2004.09.13 ASH & RFD Wrote it.
%
% Example:
% sn3dParams = load('dti_analyses/may021126_B0_sn3d.mat');
% B0 = loadAnalyze('/snarp/u1/dti/adultData/may021126/dti_analyses/may021126_B0.hdr');
% B0_new = dtiResliceAnalyzeSn3d(B0, sn3dParams, mmPerVoxOut);
% figure; imagesc(B0_new(:,:,23)); axis equal; colormap gray; axis xy;

if(~exist('nonLinearFlag') | isempty(nonLinearFlag))
    nonLinearFlag = 1;
end
if(~exist('mmPerVoxOut') | isempty(mmPerVoxOut))
    mmPerVoxOut = [2 2 2];
end

% Create a bounding box for the resliced data.
% The following is the spm default bounding box. Note that the box is
% defined in Talairach space (units = mm).
bb = [-78 -112 -50;
       78  76   85];

x = (bb(1,1):mmPerVoxOut(1):bb(2,1));
y = (bb(1,2):mmPerVoxOut(2):bb(2,2));
z = (bb(1,3):mmPerVoxOut(3):bb(2,3));

mm = sn3dParams.Dims(6,:);

[X,Y,Z] = meshgrid(x, y, z);
clear x y z;

talCoords = [X(:) Y(:) Z(:)];
newSize = size(X);
clear X Y Z;

imgCoords = mrAnatGetImageCoordsFromSn(sn3dParams, talCoords, nonLinearFlag);
imgCoords = imgCoords./repmat(mm',1,size(imgCoords,2));
imgOrigin = sn3dParams.Dims(5,:)'/2;
imgCoords = imgCoords+repmat(imgOrigin,1,size(imgCoords,2));
% We now have image coords for the space defined by the bounding box (in
% Talairach space). These image coords are in the space of the original
% image that was used to compute the sn3d params. But that may not be the
% same space as the tensor image.

% Following lines correspond to canonical transform.
% This is unnecessary because that has already been applied in Analyze format
% imgCoords = xformToTensor*[imgCoords;ones(1,size(imgCoords,2))];
% imgCoords = imgCoords(1:3,:);
% imgCoords(1,:) = imgCoords(1,:).*mm(1);
% imgCoords(2,:) = imgCoords(2,:).*mm(2);
% imgCoords(3,:) = imgCoords(3,:).*mm(3);

% Permute dimensions because of Analyze format
img = permute(img,[2,1,3]);

% Interpolate coordinate grid
img_new = myCinterp3(img, [size(img,1) size(img,2)], size(img,3), imgCoords', 0.0);
img_new = reshape(img_new, [newSize, 1]);

return;
