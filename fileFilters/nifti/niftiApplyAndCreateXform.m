function [ni] = niftiApplyAndCreateXform(nii,xformType)
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

xformType = mrvParamFormat(xformType);

xform = niftiCreateXform(nii,xformType);
%Create transform

ni = niftiApplyXform(nii,xform);

return
