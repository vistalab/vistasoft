function [nii] = niftiApplyXform(nii,xform)
%First create then apply a specified transform onto the supplied nifti
%struct.
%
% USAGE
%  nii = readNifti(niftiFullPath);
%  xformType = 'Inplane';
%  niftiApplyAndCreateXform(nii,xformType);
%
% INPUTS
%  Nifti struct
%  String specifying the transform to apply
%
% RETURNS
%  Nifti Struct
%
%
% Copyright Stanford VistaLab 2013


if(all(all(xform == eye(4))))
    warning('vista:nifti:transformError', 'The transform does not need to be applied. Returning without change.');
    return
end %if

xdim = find(abs(xform(1,:))==1);
ydim = find(abs(xform(2,:))==1);
zdim = find(abs(xform(3,:))==1);
dimOrder = [xdim, ydim, zdim];
dimFlip = [0 0 0];

pixDim = niftiGet(nii,'pixdim');
newPixDim = [pixDim(xdim), pixDim(ydim), pixDim(zdim)];




return