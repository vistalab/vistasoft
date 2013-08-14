function [defX,defY,defZ] = mrAnatInvertSn(sn, mm, bb)
%
%  [defX,defY,defZ] = mrAnatInvertSn(sn, bb)
%
% Inverts and SPM-style spatial normalization deformation ('sn').
%
% To use the inverse deformation:
% acPcCoords = sn.VF.mat*[imgCoords 1]'; % Or, get from default bb
% defCoords = inv(sn.VG.mat)*acPcCoords;
%
%
%
% %Compute and save an inverse spatial norm xform as a simple coordinate look-up table
% lutFile = coordLUT.nii.gz;
% [defX, defY, defZ] = mrAnatInvertSn(sn);
% coordLUT = int16(round(cat(4,defX,defY,defZ)));
% qto_xyz = sn.VF.mat;
% %NIFTI_INTENT_DISPVECT=1006
% intentCode = 1006;
% intentName = ['To' curSs];
% % NIFTI format requires that the 4th dim is always time,
% % so we put the deformation vector [x,y,z] in the 5th dimension.
% tmp = reshape(coordLUT,[size(defX) 1 3]);
% dtiWriteNiftiWrapper(tmp, qto_xyz, lutFile, 1, '', intentName, intentCode);
% % To use the LUT to find the MNI coordiante of an ac-pc coordinate:
% ni = niftiRead(lutFile);
% snLUT.coordLUT = squeeze(ni.data(:,:,:,1,:))
% snLUT.inMat = ni.qto_ijk;
% curPosSs = mrAnatXformCoords(snLUT, acpcCoord);
%
% HISTORY:
% 2005.01.25 RFD: wrote it.

if(~exist('spm_invdef','file'))
    spmDir = fileparts(which('spm_defaults'));
    p = fullfile(spmDir,'toolbox','Deformations');
    disp(['Adding spm deformation toolbox path (' p ')']);
    addpath(p);
end
if(~exist('bb','var')), bb = []; end
if(~exist('mm','var')), mm = []; end
%[t,r,mmTemplate] = affineDecompose(sn.VG.mat);
%[t,r,mmImg] = affineDecompose(sn.VF.mat);
%scaleMat = diag([mmTemplate./mmImg 1]);
%d = mrAnatSnToDeformation(sn,mmTemplate);
%[defX,defY,defZ] = spm_invdef(d(:,:,:,1), d(:,:,:,2), d(:,:,:,3), sn.VF.dim(1:3), inv(sn.VF.mat), sn.VF.mat*scaleMat);

d = mrAnatSnToDeformation(sn, mm, bb);
% 4th arg is 4x4 xform from mm to voxels in the coordinate frame of the inverse deformation field
% 5th arg is xform from voxels to mm in the coordinate frame of the forward deformation field
[defX,defY,defZ] = spm_invdef(d(:,:,:,1), d(:,:,:,2), d(:,:,:,3), sn.VF.dim(1:3), inv(sn.VF.mat), sn.VF.mat);
% CHECK THIS- invDef flips acpc coords when the template is left-right
% flipped. 
%[defX,defY,defZ] = spm_invdef(d(:,:,:,1), d(:,:,:,2), d(:,:,:,3), sn.VG.dim(1:3), inv(sn.VG.mat), sn.VF.mat);
return;
