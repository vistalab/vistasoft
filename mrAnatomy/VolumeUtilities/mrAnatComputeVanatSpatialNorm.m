function mrAnatComputeVanatSpatialNorm(vAnatFileName, outFileName)
% Computes an SPM2 spatial normalization and its inverse for a vAnatomy.
%
% mrAnatComputeVanatSpatialNorm(vAnatFileName, [outFileName])
%
%
% HISTORY:
% 2005.08.05 RFD: wrote it.
%

if(~exist('vAnatFileName','var') | isempty(vAnatFileName))
    vAnatFileName = mrvSelectFile('r','dat',[],'Select a vAnatomy file...');
    if isempty(vAnatFileName), return;
    elseif ~exist(vAnatFileName,'file'), error(sprintf('%s not found.\n',vAnatFileName));
    end
end
if(~exist('outFileName','var'))
    [p,f,e] = fileparts(vAnatFileName);
    outFileName = fullfile(p,[f '_sn.mat']);
end

[img, mm] = readVolAnat(vAnatFileName);
img = uint8(img);
xform = mrAnatXform(mm,size(img),'vanatomy2acpc');

%
% Compute the normalization params.
%
disp('Computing spatial norm params...');
[sn, Vtemplate] = mrAnatComputeSpmSpatialNorm(img, xform);

%
% Convert the SN params to a deformation field.
%
disp('Computing inverse spatial norm...');
% Build the bounding box needed to sample the deformation field. We want it
% to capture the entire template, so we use the template vox-to-physical xform
% (sn.VG) to generate it.
%
% We first extract scales from the template xform. We want the
% defomation field to be sampled at this same scale. That makes pulling
% values from the inverse deformation easier and saves space, since it
% isn't necessary to sample at a higher resolution than the template.
mmTemplate = sqrt(sum(sn.VG.mat(1:3,1:3).^2));
origin  = sn.VG.mat\[0 0 0 1]';
origin  = origin(1:3)';
bb = [-mmTemplate.*(origin-1) ; mmTemplate.*(sn.VG.dim(1:3)-origin)];
% Now compute the deformation:
d = single(mrAnatSnToDeformation(sn, mmTemplate, bb));

% Invert the deformation. The inverse deformation is essentially a look-up
% table that maps voxel coords to the physical space of the template. This
% is exactly what we want.
%
% 4th arg is 4x4 xform from mm to voxels in the coordinate frame of the inverse deformation field
% 5th arg is xform from voxels to mm in the coordinate frame of the forward deformation field
[defX,defY,defZ] = spm_invdef(d(:,:,:,1), d(:,:,:,2), d(:,:,:,3), sn.VF.dim(1:3), ...
                             inv(sn.VF.mat), sn.VG.mat);
                         
% We can save it as int8, since real brain templates never extend beyond
% 128mm from the origin. But, we'll check, just to be sure.
if(all(abs(defX(:))<128) & all(abs(defY(:))<128) & all(abs(defZ(:))<128))
    voxToTemplateLUT = zeros([3 size(defX)], 'int8');
    voxToTemplateLUT(1,:,:,:) = int8(round(defX));
    voxToTemplateLUT(2,:,:,:) = int8(round(defY));
    voxToTemplateLUT(3,:,:,:) = int8(round(defZ));
else
    voxToTemplateLUT = zeros([3 size(defX)], 'int16');
    voxToTemplateLUT(1,:,:,:) = int16(round(defX));
    voxToTemplateLUT(2,:,:,:) = int16(round(defY));
    voxToTemplateLUT(3,:,:,:) = int16(round(defZ));
end

fprintf('Saving to %s...\n', outFileName);
save(outFileName, 'sn', 'voxToTemplateLUT');
disp('done.');
return;



% DEBUGGING CODE:

mmPerVox = [1 1 1];

% Get a bounding box in ac-pc space that captures the whole template image.
templateMmPerVox = sqrt(sum(sn.VG(1).mat(1:3,1:3).^2));
if det(sn.VG.mat(1:3,1:3))<0, mmPerVox(1) = -mmPerVox(1); end;
templateOrigin  = sn.VG.mat\[0 0 0 1]';
templateOrigin  = templateOrigin(1:3)';
bb = [-templateMmPerVox .* (templateOrigin-1) ; templateMmPerVox.*(sn.VG(1).dim(1:3)-templateOrigin)];
% The code in mrAnatResliceSpm needs to know how to transform the image
% coords from the template's ac-pc space to actual deformation-image space. 
% The following was gleaned from spm_reslice_sn. I only vaguely understand
% it, but it seems to work.
og  = -templateMmPerVox .* templateOrigin;
M1  = [templateMmPerVox(1) 0 0 og(1) ; 0 templateMmPerVox(2) 0 og(2) ; 0 0 templateMmPerVox(3) og(3) ; 0 0 0 1];
outMmPerVox = [1 1 1];
of  = -outMmPerVox.*(round(-bb(1,:)./outMmPerVox)+1);
M2  = [outMmPerVox(1) 0 0 of(1) ; 0 outMmPerVox(2) 0 of(2) ; 0 0 outMmPerVox(3) of(3) ; 0 0 0 1];
d.inMat = inv(sn.VG(1).mat*inv(M1)*M2);


dField = mrAnatSnToDeformation(sn, [1 1 1], bb);
d.deformX = dField(:,:,:,1);
d.deformY = dField(:,:,:,2);
d.deformZ = dField(:,:,:,3);
d.outMat = inv(xform);
[imgSn, newXform] = mrAnatResliceSpm(img, d, bb, mmPerVox, [7 7 7 0 0 0]);
imgSn(isnan(imgSn)) = 0;

figure; imagesc(makeMontage(imgSn)); axis image; colormap(gray)