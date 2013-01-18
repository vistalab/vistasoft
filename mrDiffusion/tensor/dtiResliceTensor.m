function dt6_new = dtiResliceTensor(dt6, sn3dParams, mmPerVoxOut, xformToTensor)
% dt6_new = dtiResliceTensor(dt6, sn3dParams, [mmPerVoxOut], xformToTensor)
% 
% Applies spm-style sn3d parameters to a tensor volume in dt6 format. These
% sn3d parameters include a linear (affine) component and a non-linear
% component. Note that we only take into account the affine componenet when 
% correcting the tensor orientation.
%
% REQUIRES:
% spm99 or spm2 in the path.
%
% HISTORY:
% 2003.12.09 RFD & ASH Wrote it.
%
% example:
% sn3dParams = load('dti_analyses/may021126_B0_sn3d.mat');
% xformToB0 = computeCannonicalXformFromIfile('dti/B0.001');
% xformToTensor = inv(xformToB0);
% [eigVec,eigVal,mm] = dtiLoadTensor('/snarp/u1/dti/adultData/may021126/dti/Vectors.float');
% dt6 = dtiRebuildTensor(eigVec, eigVal);
% dt6_new = dtiResliceTensor(dt6, sn3dParams, mmPerVoxOut, xformToTensor);
% [newVec, newVal] = dtiSplitTensor(dt6_new);
% fa = dtiComputeFA(newVal);
% figure; imagesc(fa(:,:,23)); axis equal; colormap gray; axis xy;

if(~exist('mmPerVoxOut') | isempty(mmPerVoxOut))
    mmPerVoxOut = [2 2 2];
end
if(~exist('xformToTensor') | isempty(xformToTensor))
    xformToTensor = eye(4);
end

% create a bounding box for the resliced data
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

% ROTATE THE TENSORS 
rigidXform = dtiFiniteStrainDecompose(sn3dParams.Affine);
% Apply just the rigid rotation component of the xform to the tensors
dt6 = dtiXformTensors(dt6, rigidXform);

imgCoords = mrAnatGetImageCoordsFromSn(sn3dParams, talCoords);
imgCoords = imgCoords./repmat(mm',1,size(imgCoords,2));
imgOrigin = sn3dParams.Dims(5,:)'/2;
imgCoords = imgCoords+repmat(imgOrigin,1,size(imgCoords,2));
% We now have image coords for the space defined by the bounding box (in
% Talairach space). These image coords are in the space of the original
% image that was used to compute the sn3d params. But that may not be the
% same space as the tensor image.

imgCoords = xformToTensor*[imgCoords;ones(1,size(imgCoords,2))];
imgCoords = imgCoords(1:3,:);

imgCoords(1,:) = imgCoords(1,:).*mm(1);
imgCoords(2,:) = imgCoords(2,:).*mm(2);
imgCoords(3,:) = imgCoords(3,:).*mm(3);
% convert from matlab 1-indexing to C 0-indexing
imgCoords = imgCoords - 1;

dt6_new = dtiTensorInterp_Pajevic(dt6, [imgCoords(2,:);imgCoords(1,:);imgCoords(3,:)]', mm, 1, mm./2);

dt6_new = reshape(dt6_new, [newSize, 6]);

return;

%
% DEBUGGING:
[vec,val] = dtiSplitTensor(dt6_new);
val(val<100) = 0;
fa_interp = dtiComputeFA(val);
figure; imagesc(fa_interp(:,:,20)); axis equal xy tight off; colorbar;
b0 = loadAnalyze('dti_analyses/may021126_nB0.img');
b0 = permute(b0, [2 1 3]);
figure; imagesc(b0(:,:,20)); axis equal xy tight off; colorbar;
mask = b0>500;
fa_interp(~mask) = 0;
figure; imagesc(fa_interp(:,:,20)); axis equal xy tight off; colorbar;
m = makeMontage(fa_interp);
figure; imagesc(m); axis equal xy tight off; colorbar;