baseDir = pwd;

[f,p] = uigetfile('*.dcm','Select the first image...',fullfile(baseDir,'raw','t2','I0001.dcm'));
if(isnumeric(f)) error('user cancelled.'); end
baseDir = fileparts(p);
if(isempty(baseDir)) baseDir = pwd; end
[tmpImg,im.mmPerVox] = makeCubeIfiles(fullfile(p,f));
imName = {'pd','t2'};
im.img2std = computeCannonicalXformFromIfile(fullfile(p,f));
[f,p] = uigetfile('*.gz','Select t1 file...',baseDir);
if(isnumeric(f)) error('user cancelled.'); end
refNi = niftiRead(fullfile(p,f));
VG.uint8 = uint8(round(mrAnatHistogramClip(double(refNi.data),0.4,0.98).*255));
VG.mat = refNi.qto_xyz;
for(ii=1:2)
    im.img = tmpImg(:,:,[ii:2:end]);
    % We use header info to get us into axial orientation and ensure the
    % left-right direction is correct.
    [im.img, im.mmPerVox, dimOrder, dimFlip] = applyCannonicalXform(im.img, im.img2std, im.mmPerVox);
    [im.img, im.clipVals] = mrAnatHistogramClip(im.img,0.4,0.98);
    VF.uint8 = uint8(round(im.img.*255));
    im.origin = (size(im.img)+1)./2;
    VF.mat = [[diag(im.mmPerVox), [im.origin.*-im.mmPerVox]']; [0 0 0 1]];

    % Now align it to the T1 to get ac-pc space
    rotTrans = spm_coreg(VF,VG);
    % This composite xform will convert inplane voxel space to inplane
    % physical (VF.mat) and then inplane physical to anat physical (the
    % rigid-body rotTrans that we just computed). Since the anat physical
    % space is ac-pc space, that where we want to be.
    im.xform = spm_matrix(rotTrans(:)')*VF.mat;
    fname = fullfile(baseDir, [imName{ii} '.nii.gz']);
    dtiWriteNiftiWrapper(int16(round(im.img.*diff(im.clipVals))), im.xform, fname);
end
clear dt ip VF VG f;

t2 = niftiRead(fullfile(baseDir, 't2.nii.gz'));
handles = guidata(gcf);
newMm = [0.5 0.5 0.5];
[img,xform] = mrAnatResliceSpm(double(t2.data),t2.qto_ijk,dtiGet(handles,'t1bb'),newMm);
img(isnan(img)) = 0;
img = img./max(img(:));
handles = dtiAddBackgroundImage(handles, img, 't2', newMm, diag([1 1 1 1]));
guidata(gcf, handles);

pd = niftiRead(fullfile(baseDir, 'pd.nii.gz'));
handles = guidata(gcf);
% The nifti q-form goes converts voxel space to ac-pc space, but we want
% voxel to t1-anat, so we undo the ac-pc part.
xform = inv(handles.acpcXform)*pd.qto_xyz;
img = double(pd.data);
img = img./max(img(:));
handles = dtiAddBackgroundImage(handles, img, 'pd', t2.pixdim, xform);
guidata(gcf, handles);


%
% Starting from NIFTIS:
%
baseDir = '/biac3/wandell4/data/Achiasma/DL070825_anatomy/';
ni1 = niftiRead(fullfile(baseDir,'raw','t2pd_1.nii.gz');
ni2 = niftiRead(fullfile(baseDir,'raw','t2pd_2.nii.gz');
ref = niftiRead(fullfile(baseDir,'raw','t1.nii.gz');
im1 = ni1.data(:,:,[1:2:40]);
im2 = ni2.data(:,:,[1:2:40]);
xform =  mrAnatRegister(im2,im1);
%bb = [1 1 1; size(im1)];
%newIm2 =  mrAnatResliceSpm(double(im2), xform, bb, ni1.pixdim);
avgT2 = (double(ni1.data(:,:,[1:2:40])) + double(ni2.data(:,:,[1:2:40])))./2;
avgPd = (double(ni1.data(:,:,[2:2:40])) + double(ni2.data(:,:,[2:2:40])))./2;
avgT2 = int16(round(avgT2));
avgPd = int16(round(avgPd));

VG.uint8 = uint8(round(mrAnatHistogramClip(double(ref.data),0.4,0.98).*255));
VG.mat = ref.qto_xyz;
VF.uint8 = uint8(round(mrAnatHistogramClip(double(avgT2),0.4,0.98).*255));
origin = (size(avgT2)+1)./2;
VF.mat = [[diag(ni1.pixdim), [origin.*-ni1.pixdim]']; [0 0 0 1]];

% Now align it to the T1 to get ac-pc space
spm_defaults; global defaults;
estParams = defaults.coreg.estimate;
estParams.sep = [8 4];
rotTrans = spm_coreg(VF,VG,estParams);
acpcXform = spm_matrix(rotTrans(end,:))*VF.mat;

dtiWriteNiftiWrapper(avgT2, acpcXform, fullfile(baseDir, 't2.nii.gz'));
dtiWriteNiftiWrapper(avgPd, acpcXform, fullfile(baseDir, 'pd.nii.gz'));

