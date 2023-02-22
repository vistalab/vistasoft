% Notes for building up the management of the diffusion weighted images
%
% dwi structure
%
%  dwi = dwiCreate;
%  This returns
%    dwi.ni       - The diffusion data in the unchanged NIFTI file
%    dwi.bvecs
%    dwi.bvals
%    dwi. ...
%
% What do we mean by acpc space?  THis means the coords are arranged so
% that (0,0,0) is at the AC and PC is at a point (0,Y,0)
% (Neg X are left, hemisphere).
%
% What do we mean by image space?  This is a translation of ACPC back to
% the raw image indices (but after motion correction).
%
% The coords in ni.data are stored in image coords.
%
%  dwiGet(dwi,'mean nondiffusion signal image',coords);
%  dwiGet(dwi,'diffusion signal acpc',coords);
%  dwiGet(dwi,'bvecs image');
%  dwiGet(dwi,'bvecs acpc');
%