function dtiFiberendpointNifti(fgfile, t1file, fname, skernel,smooth)

%
% Compute the normalized density of fiber endpoints of the particular
% fascicle, and save it as a nifti file.
%
% INPUT:
% fgfile: a path to a file containing fg structure (.pdb or .mat)
% t1file: a path to a nifti file of T1 weighted image (e.g. t1.nii.gz)
% fname: a file of output nifti file
% skernel: Smoothing kernel size. 3 voxel in T1 resolution is the default.
% smooth: An option command. 1: Smoothing fiber endpoint density. 0: No
% smoothing.
% 
% EXAMPLE:
% fgfile = 'RH_VOF.pdb'
% t1file = 't1.nii.gz'
% fname = 'RH_VOF_normalizedfiberdensity.nii.gz';
% dtiFiberendpointNifti(fgfile, t1file, fname);
% 
% (C) Hiromasa Takemura, Stanford VISTA Lab 2014

%% Argument Checking
if notDefined('skernal')
 skernel= [3 3 3];
end
if notDefined('smooth')
 smooth = 1;
end

%% Read fibers and transform it into image coordinate
fg = fgRead(fgfile);
t1 = niftiRead(t1file);
xform = t1.qto_ijk;

fgkeep = dtiXformFiberCoords(fg, xform, 'img');

%% Extract fiber endpoints
fbsize = size(fgkeep.fibers);
for ph = 1:fbsize(1)
    f_coords = cell2mat(fgkeep.fibers(ph));
    fcoordsize = size(f_coords);
    fendpoints(1, ph) = round(f_coords(1,1));
    fendpoints(2, ph) = round(f_coords(2,1));
    fendpoints(3, ph) = round(f_coords(3,1));
    fendpoint2(1, ph) = round(f_coords(1,fcoordsize(2)));
    fendpoint2(2, ph) = round(f_coords(2,fcoordsize(2)));
    fendpoint2(3, ph) = round(f_coords(3,fcoordsize(2)));        
end

%% Attaching data in to nifti
nii = t1;
nii.data = zeros(t1.dim(1), t1.dim(2), t1.dim(3));

% One fiber endpoint = 1 in fiber endpoint file
for pp = 1:fbsize(1)
   nii.data(fendpoints(1, pp), fendpoints(2, pp), fendpoints(3, pp)) =  nii.data(fendpoints(1, pp), fendpoints(2, pp), fendpoints(3, pp)) + 1;
   nii.data(fendpoint2(1, pp), fendpoint2(2, pp), fendpoint2(3, pp)) =  nii.data(fendpoint2(1, pp), fendpoint2(2, pp), fendpoint2(3, pp)) + 1;    
end
%% Spatial Smoothing
if smooth ==1,
nii.data = smooth3(nii.data,'gaussian', skernel);
nii.fname = fname;
end

%% Normalizing fiber endpoint density
% normalize fiber endpoint density by max
niisave = nii;
maxnum = max(nii.data);
maxmax = max(maxnum);
maxmaxmax = max(maxmax);
niisave.data = nii.data/maxmaxmax;

%% Save files
niftiWrite(niisave,fname);