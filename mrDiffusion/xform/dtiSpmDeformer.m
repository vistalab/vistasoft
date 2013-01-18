function [dt,t1] = dtiSpmDeformer(dt, sn, t1, tensorInterpType, outMmPerVox, bb)
%
% [dt,t1] = dtiSpmDeformer(dt, sn, [t1=[]], [tensorInterpType=1], [outMmPerVox=[2 2 2]], [bb=auto])
%
% Applies the SPM2 style 'sn' deformation to a dt6 struct.
%
% tensorInterpType is the interpolation method used for the tensors. It
% should be and integer 0-7, where 0=nearest neighbor, 1=trilinear, and 2-7
% are b-splines of various degree (with 7 being the highest order, and
% presumably, the most accurate. See spm_bsplins.) The default is 1.
%
% Note that in the current implementation, weird things can happen to your 
% tensors if you use anything other than 0 or 1 (NN or trilinear). At the
% very least, you'll want to re-apply a brain mask to zero-out stuff
% outside the brain, which will get filled with junk after a b-spline
% interpolation.
%
% The anatomy images (t1 and b=0) are resliced using degree 7 b-splines.
%
% HISTORY:
% 2005.01.20 RFD: wrote it.
% 2007.10.29 RFD: adapted for use with new NIFTI-based dt6 format

% dt can either be a dt6 struct or a filename pointing to a dt6 file.
if(~exist('dt','var'))
    dt = '';
end

if(ischar(dt))
    [dt, t1] = dtiLoadDt6(dt);
end
if(~exist('t1','var'))
    t1 = [];
end
if(~exist('tensorInterpType','var') || isempty(tensorInterpType))
    tensorInterpType = 1;
end
if(~exist('outMmPerVox','var') || isempty(outMmPerVox))
    outMmPerVox = [1 1 1];
end
guiMode = 0;

anatSplineParams = [7 7 7 0 0 0];
if(tensorInterpType<0)
    useLogInterp = true;
    tensorInterpType = abs(tensorInterpType);
else
    useLogInterp = false;
end
tensorSplineParams = [tensorInterpType tensorInterpType tensorInterpType 0 0 0];

if(~exist('bb','var')||isempty(bb))
    % Get a bounding box in ac-pc space that captures the whole template image.
    bb = round(mrAnatXformCoords(sn.VG(1).mat, [1 1 1; sn.VG(1).dim(1:3)]));
    %bb = [-80 -120 -60; 80 90 90];
end

% The code in mrAnatResliceSpm needs to know how to transform the image
% coords from the template's ac-pc space to actual deformation-image space. 
% The following was gleaned from spm_reslice_sn. I only vaguely understand
% it, but it seems to work.
templateMmPerVox = sqrt(sum(sn.VG(1).mat(1:3,1:3).^2));
if det(sn.VG.mat(1:3,1:3))<0, templateMmPerVox(1) = -templateMmPerVox(1); end;
templateOrigin  = sn.VG.mat\[0 0 0 1]';
templateOrigin  = templateOrigin(1:3)';
og  = -templateMmPerVox .* templateOrigin;
M1  = [templateMmPerVox(1) 0 0 og(1) ; 0 templateMmPerVox(2) 0 og(2) ; 0 0 templateMmPerVox(3) og(3) ; 0 0 0 1];
of  = -outMmPerVox.*(round(-bb(1,:)./outMmPerVox)+1);
M2  = [outMmPerVox(1) 0 0 of(1) ; 0 outMmPerVox(2) 0 of(2) ; 0 0 outMmPerVox(3) of(3) ; 0 0 0 1];
d.inMat = inv(sn.VG(1).mat*inv(M1)*M2);

%
% Convert SPM params to a deformation field
%
% This isn't necessary for warping the images, but we'll need it for
% computing the PPD adjustments to the tensor field. Also, the image
% warping goes much fater when we pre-compute the deformation field.
%
dField = mrAnatSnToDeformation(sn, outMmPerVox, bb);
d.deformX = dField(:,:,:,1);
d.deformY = dField(:,:,:,2);
d.deformZ = dField(:,:,:,3);

if(~isempty(t1))
    %
    % Deform the T1
    %
    disp('Warping T1...');
    % % The code in mrAnatResliceSpm needs to know how to transform the image
    % % coords from ac-pc space to actual voxel space.
    % sn.outMat = inv(dt.anat.xformToAcPc);
    % [img, newAnatXform] = mrAnatResliceSpm(dt.anat.img, sn, bb, dt.anat.mmPerVox);
    %
    % We also need to tell the reslicer how to convert the values in the deformation
    % field (which are in ac-pc space) into image coords. Since we used a
    % bounding box based on the T1, this is simply the same xform as d.inMat.
    % If, for example, we wanted a larger bb, then we would have to adjust the
    % origin of this xform appropriately.
    d.outMat = inv(t1.xformToAcpc);
    [img, newAnatXform] = mrAnatResliceSpm(double(t1.img), d, bb, t1.mmPerVoxel, anatSplineParams, guiMode);
    img(isnan(img)) = 0;
    t1.img = img;
    t1.xformToAcpc = newAnatXform;
    if(isfield(t1,'brainMask') && ~isempty(t1.brainMask))
        disp('Warping brainMask...');
        [img, newAnatXform] = mrAnatResliceSpm(double(t1.brainMask), d, bb, t1.mmPerVoxel, [1 1 1 0 0 0], guiMode);
        img(isnan(img)) = 0;
        t1.brainMask = img>=0.5;
    end
end

%
% Deform the B0
%
disp('Warping B0...');
% mmPerVox = dt.mmPerVoxel;
% sn.outMat = inv(dt.anat.xformToAcPc*dt.xformToAnat);
% [dt.b0, newB0Xform] = mrAnatResliceSpm(dt.b0, sn, bb, mmPerVox);
d.outMat = inv(dt.xformToAcpc);
[img, newB0Xform] = mrAnatResliceSpm(dt.b0, d, bb, dt.mmPerVoxel, anatSplineParams, guiMode);
img(isnan(img)) = 0;
rng = [min(dt.b0(:)) max(dt.b0(:))];
img(img<rng(1)) = rng(1); img(img>rng(2)) = rng(2);
dt.b0 = img;
dt.xformToAcpc = newB0Xform;
if(isfield(dt,'brainMask') && ~isempty(dt.brainMask))
  disp('Warping brainMask...');
  img = mrAnatResliceSpm(double(dt.brainMask), d, bb, dt.mmPerVoxel, [1 1 1 0 0 0], guiMode);
  img(isnan(img)) = 0;
  dt.brainMask = img>=0.5;
end


%
% Deform the Tensor field
%
% This uses the same deformation as the B0.
disp('Warping Tensor field...');
if(useLogInterp)
    disp('  Using log-space tensor interpolation.');
    [vec,val] = dtiEig(dt.dt6);
    % fix bad tensors
    val(val<0) = 0;
    nz = val>0;
    val(nz) = log(val(nz));
    dt.dt6 = dtiEigComp(vec,val);
    [img, newTensorXform] = mrAnatResliceSpm(dt.dt6, d, bb, dt.mmPerVoxel, tensorSplineParams, guiMode);
    [vec,val] = dtiEig(img);
    % Interpolation may have introduced some negative values
    val(val<0) = 0;
    nz = val>0;
    val(nz) = exp(val(nz));
    img = dtiEigComp(vec,val);
else
    [img, newTensorXform] = mrAnatResliceSpm(dt.dt6, d, bb, dt.mmPerVoxel, tensorSplineParams, guiMode);
end
% Spline interpolation on the tensor field creates noise in the background
% (non-brain) areas. 
% If any one of the 6 tensor elements gets NANed, we want to zero-out the
% whole tensor. ("img(isnan(img))==0" would probably suffice, but we want 
% to be thorough, since some interpolation algorithms can do weird things.)
nanMask = isnan(img(:,:,:,1));
for(ii=2:6) nanMask = nanMask & isnan(img(:,:,:,ii)); end
img(repmat(nanMask, [1,1,1,6])) = 0;
dt.dt6 = img;

% Since we are rotating the tensors *after* reslicing the tensor field, we
% need to apply the same deformation field that we used to do the spatial
% warping. If we applied the tensor reorientation before reslicing, then we
% would apply the inverse deformation. Note that the deformation field
% tells us where to pull data from (see notes below), so it is
% computationally more efficient to apply the PPD after reslicing so that
% we don't need to invert the deformation. 
%
% 2005.05.02 RFD: I checked that this code does the right thing by
% applying large deformations that simulated rotations and then
% doing long-range fiber tracking, which is quite sensitive to
% small biases in tensor orientation. I didn't do exhaustive tests
% (eg. applying more complicated deformations), but if it gets a
% basic deformation right, it *should* get everything
% right. Someday, though, we should develop a more thorough
% test-suite.
disp('Rotating Tensors (Preserving Principal Direction)...');
% Get a deformation field on the tensor sampling grid:
mm = dt.mmPerVoxel;
dField = mrAnatSnToDeformation(sn, mm, bb);
% This gives us an absolute deformation field- essentailly a look-up
% table telling us, for each voxel in the template space, which point
% in the source image space to pull data from. But we want a relative
% deformation field to give to the PPD algorithm. So, we remove the samplig
% grid to leave just the relative offsets.
x   = (bb(1,1):mm(1):bb(2,1));
y   = (bb(1,2):mm(2):bb(2,2));
z   = (bb(1,3):mm(3):bb(2,3));
for(ii=1:length(z))
    [X,Y,Z] = ndgrid(x, y, z(ii));
    dField(:,:,ii,1) = (X-dField(:,:,ii,1))./mm(1);
    dField(:,:,ii,2) = (Y-dField(:,:,ii,2))./mm(2);
    dField(:,:,ii,3) = (Z-dField(:,:,ii,3))./mm(3);
end
%PPD Reorientation of dt6 image
dt.dt6 = dtiXformTensorsPPD(dt.dt6, dField);


% Fix talNorm params
dt.anat.talScale.sac = 1;
dt.anat.talScale.iac = 1;
dt.anat.talScale.lac = 1;
dt.anat.talScale.rac = 1;
dt.anat.talScale.aac = 1;
dt.anat.talScale.acpc = 1;
dt.anat.talScale.ppc = 1;
return;
