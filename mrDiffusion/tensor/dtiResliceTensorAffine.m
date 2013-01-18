function dt6_new = dtiResliceTensorAffine(dt6, xform, mmPerVoxIn, boundingBox, mmPerVoxOut)
% dt6_new = dtiResliceTensorAffine(dt6, xform, mmPerVoxIn, [boundingBox], [mmPerVoxOut])
% 
% Applies an affine transform to a tensor volume in dt6 format.
%
% REQUIRES:
% spm99 or spm2 in the path.
%
% HISTORY:
% 2004.02.01 RFD & ASH Wrote it.
% 2004.08.06 RFD & ASH- we now use the Finite Strain method, which means
% that we no longer ignore shears.
% 2005.03.25 RFD- fixed the bug that was introduced with the last edit
% (2004.08.06). The tensor rotation was the inverse of what it should have
% been! I also think that applying the tensor rotation after the
% interpolation was introducing some subtle artifacts, so I switched back
% to rotating the tensors before interpolating (the order really shouldn't
% matter, so we should look into this more to understand why it does.)
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
    mmPerVoxOut = [1 1 1];
end

if(~exist('boundingBox') | isempty(boundingBox))
    % create a default bounding box for the resliced data.
    % The following is the spm default bounding box. Note that the box is
    % defined in Talairach space (units = mm).
    boundingBox = [-78 -120 -60;
                    78  80   85];
end

x = (boundingBox(1,1):mmPerVoxOut(1):boundingBox(2,1));
y = (boundingBox(1,2):mmPerVoxOut(2):boundingBox(2,2));
z = (boundingBox(1,3):mmPerVoxOut(3):boundingBox(2,3));

[X,Y,Z] = meshgrid(x, y, z);
clear x y z;

talCoords = [X(:) Y(:) Z(:)];
newSize = size(X);
clear X Y Z;

% Does it matter if tensor rotation is done before or after rotation?
% ROTATE THE TENSORS
% NOTE: we want to apply inv(xform) to the tensors, since xform maps from
% the new space to the old (the correct mapping for the interpolation,
% since we interpolate by creating a grid in the new space and fill it by
% pulling data from the old space.)
rigidXform = dtiFiniteStrainDecompose(inv(xform));
% Apply just the rigid rotation component of the xform to the tensors
dt6 = dtiXformTensors(dt6, rigidXform);

imgCoords = mrAnatXformCoords(xform, talCoords)';
%imgCoords = imgCoords./repmat(mmPerVoxIn',1,size(imgCoords,2));

% the imgCoords are specified in mm, as an offset from the origin. So, we
% convert the 1-indexed imgCoords from mrAnatXformCoords to zero-indexed and 
% scale to real mm.
imgCoords = imgCoords - 1;
imgCoords(1,:) = imgCoords(1,:).*mmPerVoxIn(1);
imgCoords(2,:) = imgCoords(2,:).*mmPerVoxIn(2);
imgCoords(3,:) = imgCoords(3,:).*mmPerVoxIn(3);

% We need to mask away the crazy values outside the head.
% Also, the Pajevic algorithm will fold the data over to deal with the
% edges. That might be nice for computing edge values, but it makes for
% ugly images and crazy fiber tacings. The following will build a mask of
% the good image values (ie. values inside the head), interpolate it to the
% new volume size, and then invert it so it marks bad values, those
% outside the head.
dt6_mask = sum(abs(dt6),4)>0.001;
dt6_mask = dtiResliceVolume(double(dt6_mask), xform, boundingBox, mmPerVoxOut);
dt6_mask = dt6_mask>0.5;
dt6_mask = dtiCleanImageMask(dt6_mask);
%figure; imagesc(makeMontage(dt6_mask)); axis equal off; colormap gray;
dt6_mask = ~dt6_mask;

% *** HACK so that matlab can find the shared library
old = pwd;
cd(fileparts(which('dtiTensorInterp_Pajevic')));
dt6_new = dtiTensorInterp_Pajevic(dt6, [imgCoords(1,:);imgCoords(2,:);imgCoords(3,:)]', mmPerVoxIn, 1, mmPerVoxIn./2);
cd(old);
dt6_new(repmat(dt6_mask(:),1,6)) = 0;
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