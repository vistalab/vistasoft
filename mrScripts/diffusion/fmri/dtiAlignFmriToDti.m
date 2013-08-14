
baseDir = pwd;

if(~exist(fullfile(baseDir, 'inplane.nii.gz'),'file'))
    % Inplane NIFTI hasn't been built.
    [f,p] = uigetfile('*.dcm','Select the first inplane image...',fullfile(baseDir,'inplane','I0001.dcm'));
    if(isnumeric(f)) error('user cancelled.'); end
    ip.img = makeCubeIfiles(fullfile(p,f));
    % We use header info to get us into axial orientation and ensure the
    % left-right direction is correct.
    [ip.img2std,bname,ip.mmPerVox] = computeCannonicalXformFromIfile(fullfile(p,f));
    [ip.img, ip.mmPerVox, dimOrder, dimFlip] = applyCannonicalXform(ip.img, ip.img2std, ip.mmPerVox)
    [ip.img, ip.clipVals] = mrAnatHistogramClip(ip.img,0.4,0.98);
    VF.uint8 = uint8(round(ip.img.*255));
    ip.origin = (size(ip.img)+1)./2;
    VF.mat = [[diag(ip.mmPerVox), [ip.origin.*-ip.mmPerVox]']; [0 0 0 1]];

    % Now align it to the T1 to get ac-pc space
    [f,p] = uigetfile('*.mat','Select dt6 file...',baseDir);
    if(isnumeric(f)) error('user cancelled.'); end
    dt = load(fullfile(p,f), 'anat');
    dt.anat.img = mrAnatHistogramClip(double(dt.anat.img),0.4,0.98);
    VG.uint8 = uint8(dt.anat.img.*255+0.5);
    VG.mat = dt.anat.xformToAcPc;
    rotTrans = spm_coreg(VF,VG);
    % This composite xform will convert inplane voxel space to inplane
    % physical (VF.mat) and then inplane physical to anat physical (the
    % rigid-body rotTrans that we just computed). Since the anat physical
    % space is ac-pc space, that where we want to be.
    ip.xform = spm_matrix(rotTrans(:)')*VF.mat;

    dtiWriteNiftiWrapper(int16(round(ip.img.*diff(ip.clipVals))), ip.xform, fullfile(baseDir, 'inplane.nii.gz'));
    clear dt ip VF VG f;
end

ipFile = fullfile(baseDir, 'inplane.nii.gz');
if(~exist(ipFile,'file'))
  [f,p] = uigetfile('*.nii.gz','Select the Inplane NIFTI file...',baseDir);
  if(isnumeric(f)) error('user cancelled.'); end
  ipFile = fullfile(p,f);
end
inplane = niftiRead(ipFile);
%handles = guidata(gcf);
% The nifti q-form goes converts voxel space to ac-pc space, but we want
% voxel to t1-anat, so we undo the ac-pc part.
%xform = inv(handles.acpcXform)*inplane.qto_xyz;
%img = double(inplane.data);
%img = img./max(img(:));
%handles = dtiAddBackgroundImage(handles, img, 'inplane', inplane.pixdim, xform);
%guidata(gcf, handles);

[f,p] = uigetfile('*.img','Select the unnormalized functional data...',baseDir);
if(isnumeric(f)) error('user cancelled.'); end
[fun.img, fun.mm, fun.hdr] = loadAnalyze(fullfile(p,f));
% swap LR
fun.img = flipdim(fun.img,1);
% Mapping functionals to ac-pc involves mapping the functional
% voxel space to the inplane voxel space. This assumes that
% the function and inplane voxel spaces are the same, except for a scale
% difference.
ipToFun = diag([abs(fun.mm) 1]) * inv(diag([inplane.pixdim 1]));
dtiWriteNiftiWrapper(fun.img, inplane.qto_xyz*ipToFun, fullfile(baseDir, 'resting_fmri.nii.gz'));


% Normalize the functional data:

[f,p] = uigetfile('*.nii.gz','Select the NIFTI file to be normalized...',pwd);
if(isnumeric(f)) error('user cancelled.'); end
niFile = fullfile(p,f);
[f,p] = uigetfile('*.mat','Select the dt6 file...',fileparts(p));
if(isnumeric(f)) error('user cancelled.'); end
dt6File = fullfile(p,f);
ni = niftiRead(niFile);
dt = load(dt6File, 'anat','t1NormParams');

sn = dt.t1NormParams(2).sn;
outMmPerVox = [2 2 2];
% Get a bounding box in ac-pc space that captures the whole template image.
templateMmPerVox = sqrt(sum(sn.VG(1).mat(1:3,1:3).^2));
if det(sn.VG.mat(1:3,1:3))<0, templateMmPerVox(1) = -templateMmPerVox(1); end;
templateOrigin  = sn.VG.mat\[0 0 0 1]';
templateOrigin  = templateOrigin(1:3)';
bb = [-templateMmPerVox .* (templateOrigin-1) ; templateMmPerVox.*(sn.VG(1).dim(1:3)-templateOrigin)];
% should be bb = [-80 -120 -60; 80 90 90];
og  = -templateMmPerVox .* templateOrigin;
M1  = [templateMmPerVox(1) 0 0 og(1) ; 0 templateMmPerVox(2) 0 og(2) ; 0 0 templateMmPerVox(3) og(3) ; 0 0 0 1];
of  = -outMmPerVox.*(round(-bb(1,:)./outMmPerVox)+1);
M2  = [outMmPerVox(1) 0 0 of(1) ; 0 outMmPerVox(2) 0 of(2) ; 0 0 outMmPerVox(3) of(3) ; 0 0 0 1];
d.inMat = inv(sn.VG(1).mat*inv(M1)*M2);
dField = mrAnatSnToDeformation(sn, outMmPerVox, bb);
d.deformX = dField(:,:,:,1);
d.deformY = dField(:,:,:,2);
d.deformZ = dField(:,:,:,3);
d.outMat = ni.qto_ijk;
[img, newXform] = mrAnatResliceSpm(double(ni.data), d, bb, outMmPerVox, [1 1 1 0 0 0]);
newXform = sn.VG(1).mat*diag([outMmPerVox 1]);
[p,f,e] = fileparts(niFile); [junk,f] = fileparts(f);
outFile = fullfile(p,[f '_sn.nii.gz']);
dtiWriteNiftiWrapper(img, newXform, outFile);


