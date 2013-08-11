function relaxAlignRefToAnat(anatFile, refFile, showFigs)
%
% relaxAlignRefToAnat([anatFile=uigetfile], [refFile=uigetfile], [showFigs=true])
% 
% Computes the transform that will align the CRI reference to the
% specified anatomy image (usually a T1-weighted SPGR that has been
% ac-pc aligned). The resulting transform is saved in the CRI
% reference NIFTI header.
%
% HISTORY:
% 2007.03.02 RFD: wrote it.

if(~exist('showFigs','var')||isempty(showFigs))
  showFigs = true;
end
if(~exist('anatFile','var')||isempty(anatFile))
  [f, p] = uigetfile({'*.nii;*.nii.gz','NIFTI'}, 'Select anatomical target image file...');
  if(isnumeric(f))
    disp('User canceled.');
    return;
  end
  anatFile = fullfile(p,f);
end
if(~exist('refFile','var')||isempty(refFile))
  [f, p] = uigetfile({'*.nii;*.nii.gz','NIFTI'}, 'Select CRI reference image file...');
  if(isnumeric(f))
    disp('User canceled.');
    return;
  end
  refFile = fullfile(p,f);
end
if(~exist('additionalNiftis','var'))
  additionalNiftis = {};
end

spm_defaults; global defaults;
defaults.analyze.flip = 0;

anat = niftiRead(anatFile);
ref = niftiRead(refFile);

% *** We should prompt the user for some parameters here, like default clip
% values, type of registration, etc.
VF.uint8 = uint8(round(mrAnatHistogramClip(double(ref.data),0.4,0.99).*255));
% We assume that the NIFTI/Analyze xform brings us to ac-pc space.
% Perhaps call mrAnatSetNiftiXform to let the user set this
% manually?
VF.mat = ref.qto_xyz;
if(any(abs(VF.mat(1:3,4)')<10))
    % try to fix ill-formed xforms (or at least make them sane)
    mm = ref.pixdim(1:3);
    imgOrigin = (size(ref.data)+1)./2;
    VF.mat = [[diag(mm), [imgOrigin.*-mm]']; [0 0 0 1]];
end

VG.uint8 = uint8(round(mrAnatHistogramClip(double(anat.data),0.4,0.99).*255));
VG.mat = anat.qto_xyz;
if(showFigs)
  fh = figure;
  dtiShowAlignFigure(fh,VG,VF);
  pause(1);
end
rotTrans = spm_coreg(VF,VG);
% This composite xform will convert the image voxel space to image
% physical (VF.mat) and then image physical to curBg physical (the
% rigid-body rotTrans that we just computed). Since the curBg physical
% space is ac-pc space, that is where we want to be.
xform = spm_matrix(rotTrans(:)')*VF.mat;
if(showFigs)
  clf(fh);
  VF.mat=xform; dtiShowAlignFigure(fh,VG,VF);
end

ref.qform_code = 2;
ref.qto_xyz = xform;
writeFileNifti(ref);

return;
