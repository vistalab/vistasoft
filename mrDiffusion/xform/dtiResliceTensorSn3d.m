function dt6_new = dtiResliceTensorSn3d(dt6, sn3dParams, nonLinearFlag, mmPerVoxOut, xformToTensor, rotTensorMethod)
% dt6_new = dtiResliceTensor(dt6, sn3dParams, [nonLinearFlag], [mmPerVoxOut], [xformToTensor], [rotTensorMethod])
% 
% Applies spm-style sn3d parameters to a tensor volume in dt6 format.
% These sn3d parameters include a linear (affine) component and a non-linear component.
%
% INPUT:
%   dt6                 XxYxZx6 tensor array. If last dimension is 1 then data is
%                       treated as scalar volume.
%   sn3dParams          The sn3d parameter structure from SPM.
%   nonLinearFlag       If 1 (default), non-linear component is included.
%                       If 0, then non-linear component is not included.
%   mmPerVoxOut         mm per voxel in resliced array.
%   xformToTensor       Linear xform required with raw data. Not required if
%                       data is in Analyze format (set to identity).
%   rotTensorMethod     Method of tensor rotation. Ignored if data is scalar.
%                           'SPM' (using spm_matrix.m) - default
%                           'FS' (finite strain)
%                           'PPD' (preservation fo principal direction)
%                           '' (no rotation)
%
% OUTPUT:
%   dt6_new             XxYxZx6 tensor array, or XxYxZ if data is scalar.
%
% REQUIRES:
% spm99 or spm2 in the path.
%
% HISTORY:
% 2004.09.13 ASH & RFD Wrote it.
% 2005.01.12 RFD: Cleaning code, adding support for SPM2 spatial norm
% params, and adding code to do a proper tensor correction with nonlinear
% deformations.
%
% Example:
% sn3dParams = load('dti_analyses/may021126_B0_sn3d.mat');
% xformToB0 = computeCannonicalXformFromIfile('dti/B0.001');
% xformToTensor = inv(xformToB0);
% [eigVec,eigVal,mm] = dtiLoadTensor('/snarp/u1/dti/adultData/may021126/dti/Vectors.float');
% dt6 = dtiRebuildTensor(eigVec, eigVal);
% dt6_new = dtiResliceTensorSn3d(dt6, sn3dParams, mmPerVoxOut, xformToTensor);
% [newVec, newVal] = dtiSplitTensor(dt6_new);
% fa = dtiComputeFA(newVal);
% figure; imagesc(fa(:,:,23)); axis equal; colormap gray; axis xy;

if (size(dt6,4)~=6 & size(dt6,4)~=1),
    error('Wrong input format')
end
if(~exist('nonLinearFlag') | isempty(nonLinearFlag))
    nonLinearFlag = 1;
end
if(~exist('mmPerVoxOut') | isempty(mmPerVoxOut))
    mmPerVoxOut = [2 2 2];
end
if(~exist('xformToTensor') | isempty(xformToTensor))
    xformToTensor = eye(4);
end
if(~exist('rotTensorMethod') | isempty(rotTensorMethod))
    rotTensorMethod = 'SPM';
end

% Create a bounding box for the resliced data.
% The following is the spm default bounding box. Note that the box is
% defined in Talairach space (units = mm).
bb = [-78 -112 -50;
       78  76   85];

x = (bb(1,1):mmPerVoxOut(1):bb(2,1));
y = (bb(1,2):mmPerVoxOut(2):bb(2,2));
z = (bb(1,3):mmPerVoxOut(3):bb(2,3));

if(isfield(sn3dParams, 'Dims'))
    mm = sn3dParams.Dims(6,:)';
else
    % support spm2 style sn params
    mm = diag(sn3dParams.VF.mat(1:3,1:3));
end

[X,Y,Z] = meshgrid(x, y, z);
clear x y z;

talCoords = [X(:) Y(:) Z(:)];
newSize = size(X);
clear X Y Z;

imgCoords = mrAnatGetImageCoordsFromSn(sn3dParams, talCoords, nonLinearFlag);
if(isfield(sn3dParams,'VF'))
    [trans,rot,mm,skew] = affineDecompose(sn3dParams.VF.mat);
    imgCoords = mrAnatXformCoords(inv(sn3dParams.VF.mat)*xformToTensor, imgCoords')';
else
    mm = sn3dParams.Dims(6,:)';
    imgCoords = imgCoords./repmat(mm,1,size(imgCoords,2));
    imgOrigin = sn3dParams.Dims(5,:)'/2;
    imgCoords = imgCoords+repmat(imgOrigin,1,size(imgCoords,2));
    % We now have image coords for the space defined by the bounding box (in
    % Talairach space). These image coords are in the space of the original
    % image that was used to compute the sn3d params. But that may not be the
    % same space as the tensor image.
    imgCoords = mrAnatXformCoords(xformToTensor, imgCoords);
    imgCoords(1,:) = imgCoords(1,:).*mm(1);
    imgCoords(2,:) = imgCoords(2,:).*mm(2);
    imgCoords(3,:) = imgCoords(3,:).*mm(3);
end

fprintf('Interpolate coordinate grid...\n')
if (size(dt6,4)==6),
    % convert from matlab 1-indexing to C 0-indexing
	imgCoords = imgCoords - 1;
    
	% *** HACK so that matlab can find the shared library
	old = pwd;
	cd(fileparts(which('dtiTensorInterp_Pajevic')));
	dt6_new = dtiTensorInterp_Pajevic(dt6, [imgCoords(2,:);imgCoords(1,:);imgCoords(3,:)]', mm, 1, mm./2);
	cd(old);
    dt6_new = reshape(dt6_new, [newSize, 6]);
else
    dt6_new = myCinterp3(dt6, [size(dt6,1) size(dt6,2)], size(dt6,3), imgCoords', 0.0);
    dt6_new = reshape(dt6_new, [newSize, 1]);
end
dt6_new = real(dt6_new);

% ROTATE THE TENSORS
fprintf('Rotate tensors...\n')
xformTalToImg = sn3dParams.MF * sn3dParams.Affine * inv(sn3dParams.MG);
xformImgToTal = inv(xformTalToImg);

% Apply just the rigid rotation component of the xform to the tensors
if (size(dt6,4)==6),
    switch rotTensorMethod,
    case 'SPM',
        % spm_matrix method
		p = spm_imatrix(xformImgToTal);
		p([1:3,10:12]) = 0; p(7:9) = 1;
		rot = spm_matrix(p); rot = rot(1:3,1:3);
     	dt6_new = dtiXformTensors(dt6_new, rot);
    case 'FS',
        % Finite strain method
    	rigidXform = dtiFiniteStrainDecompose(xformImgToTal);
     	dt6_new = dtiXformTensors(dt6_new, rigidXform);
    case 'PPD',
        % Preservation of principal direction method
        dt6_new = dtiXformTensorsPPD(dt6_new, xformImgToTal);
    end
end
% Apply cannonical transform
% xformToTensor is same as inv(xformToTensor)
dt6_new = dtiXformTensors(dt6_new, xformToTensor);

return;
