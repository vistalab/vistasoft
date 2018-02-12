function vistaAlignment = fs_tkreg2vista(R, func, anat)
%
% Test:
% pth = '/Volumes/server/Projects/Retinotopy/wl_subj042/20170713_PrismaPilot';
% func = fullfile(pth,'preproc/distort/unwarp/distortion_averaged_corrected.nii.gz');
% anat = fullfile(pth, '3DAnatomy/t1.nii.gz');
% R = [...
%    9.998847842216492e-01 1.509265881031752e-02 -1.660096342675388e-03 -1.650448679924011e+00 
%    5.567267071455717e-03 -2.626409232616425e-01 9.648773074150085e-01 -2.170687866210938e+01
%    -1.412637531757355e-02 9.647750854492188e-01 2.626940906047821e-01 6.907639980316162e+00
%    0 0 0 1];
% vistaAlignment = fs_tkreg2vista(R, func, anat)

% Get the functional transform from voxels to TKR
ni.f    = niftiRead(func);
f.dim   = niftiGet(ni.f, 'dim');
f.res   = niftiGet(ni.f, 'pixdim');
Tf      = vox2ras_tkreg(f.dim, f.res);

% Get the anatomical transform from voxels to TKR
ni.a    = niftiRead(anat);
a.dim   = niftiGet(ni.a, 'dim');
a.res   = niftiGet(ni.a, 'pixdim');
Ta      = vox2ras_tkreg(a.dim, a.res);

% Compute the transform Q0, from anatomy to functional data in freesurfer
% space. (Note that FS matrices are 0 indexed.)
Q0 = inv(Tf)*R*Ta;

% Compute the transform Q1, Q0 transformed for 1-indexing
xform0to1 = [[eye(3); zeros(1,3)] ones(4,1)];
Q1 = xform0to1 * Q0 * inv(xform0to1);

% Get the transforms used by vistasoft to re-orient nifti files (both
% inplane - ie functional - and anatomical)
f2v      = niftiCreateXform(ni.f,'inplane');
[~, a2v] = niftiApplyCannonicalXform(ni.a);

% Get the additional transform used by vistasoft to transform the nifti
% anatomical (RAS) to a 3D matlab array (IPR)
aRAS2IPR = [...
    0 0 -1 a.dim(3)+1
    0 -1 0 a.dim(2)+1
    1 0 0 0
    0 0 0 1];

% Combine the two anatomical transforms into 1
a2v = round(aRAS2IPR * a2v); 

% put it all together: (from right to left): 
%       vista anatomical (IPR) => 
%       native anatomical => 
%       native functional =>
%       vista functional

a2f = f2v  * Q1 * inv(a2v);

% and the inverse, which is what vistasoft stores
f2a = inv(a2f);
vistaAlignment = f2a;

end