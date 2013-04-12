function [nii] = niftiApplyXform(nii,xform)
%First create then apply a specified transform onto the supplied nifti
%struct.
%
% USAGE
%  nii = readNifti(niftiFullPath);
%  xformType = 'Inplane';
%  xform = niftiCreateXform(nii,xformType);
%  nii = niftiApplyXform(nii,xform);
%
% INPUTS
%  Nifti struct
%  Transform matrix in canonical format (i.e. of magnitude 1)
%
% RETURNS
%  Nifti Struct
%
%
% Copyright Stanford VistaLab 2013


xformLocal = xform(1:3,1:3);

if(all(all(xformLocal == eye(3))))
    fprintf('The transform does not need to be applied. Returning nifti without change.');
    return %No need to do the rest of the calculations
end %if

nii = niftiCheckQto(nii); %This is necessary to set up the qto_ijk and xyz for the transform


xdim = find(abs(xformLocal(1,:))==1);
ydim = find(abs(xformLocal(2,:))==1);
zdim = find(abs(xformLocal(3,:))==1);
dimOrder = [xdim, ydim, zdim];
%dimFlip = [0 0 0];


nii = niftiSet(nii,'data',permute(niftiGet(nii,'data'),[dimOrder,4,5]));

if (xformLocal(1,xdim)<0)
    %dimFlip(xdim) = 1;
    nii = niftiSet(nii,'data',flipdim(niftiGet(nii,'data'),1));
end

if (xformLocal(2,ydim)<0)
    %dimFlip(xdim) = 2;
    nii = niftiSet(nii,'data',flipdim(niftiGet(nii,'data'),2));
end

if (xformLocal(3,zdim)<0)
    %dimFlip(xdim) = 3;
    nii = niftiSet(nii,'data',flipdim(niftiGet(nii,'data'),3));
end

%Now the permutations on the data are complete, now we can update the
%struct with the new data

pixDim = niftiGet(nii,'pixdim');
newPixDim = [pixDim(xdim), pixDim(ydim), pixDim(zdim)];
nii = niftiSet(nii,'pixdim',newPixDim);

newDim = niftiGet(nii,'dim');
newSize = size(niftiGet(nii,'data'));
newDim(1:numel(newSize)) = newSize; %Overwrite the size portion with the new size
nii = niftiSet(nii,'dim',newDim);

nii = niftiSetQto(nii,inv(xform*niftiGet(nii,'qto_ijk')));

if(any(any(niftiGet(nii,'sto_xyz')>0)>0))
    %ni.sto_ijk = canXform*ni.sto_ijk;
    nii = niftiSet(nii, 'sto_ijk',xform*niftiGet(nii,'sto_ijk'));
    %ni.sto_xyz = inv(ni.sto_ijk);
	nii = niftiSet(nii, 'sto_xyz',inv(niftiGet(nii,'sto_ijk')));
end

<<<<<<< HEAD
%In case the nifti does not have the following fields, let's check them
%before we 
if (~isempty(niftiGet(nii,'freqdim')) && niftiGet(nii,'freqdim'))
    nii = niftiSet(nii,'freqdim', dimOrder(niftiGet(nii,'freqdim')));
else
    warning('nifti;ValuesNotSet','No freqdim field set in the nifti. Nifti stored at: %s', niftiGet(nii,'FName'));
end

if (~isempty(niftiGet(nii,'phasedim')) && niftiGet(nii,'phasedim'))
    nii = niftiSet(nii,'phasedim', dimOrder(niftiGet(nii,'phasedim')));
else
    warning('nifti;ValuesNotSet','No phasedim field set in the nifti. Nifti stored at: %s', niftiGet(nii,'FName'));
end

if (~isempty(niftiGet(nii,'slicedim')) && niftiGet(nii,'slicedim'))
    %Should never get here as niftiGet returns '3' if slicedim is 0, but
    %good to be careful anyway
    nii = niftiSet(nii,'slicedim', dimOrder(niftiGet(nii,'slicedim')));
else
    warning('nifti;ValuesNotSet','No slicedim field set in the nifti. Nifti stored at: %s', niftiGet(nii,'FName'));
end

return