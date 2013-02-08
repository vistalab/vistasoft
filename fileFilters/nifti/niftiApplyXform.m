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


if(all(all(xform == eye(4))))
    warning('vista:nifti:transformError', 'The transform does not need to be applied. Returning without change.');
    return
end %if

xformLocal = xform(1:3,1:3);

xdim = find(abs(xformLocal(1,:))==1);
ydim = find(abs(xformLocal(2,:))==1);
zdim = find(abs(xformLocal(3,:))==1);
dimOrder = [xdim, ydim, zdim];
%dimFlip = [0 0 0];

pixDim = niftiGet(nii,'pixdim');
newPixDim = [pixDim(xdim), pixDim(ydim), pixDim(zdim)];

nii = niftiSet(nii,'data',permute(niftiGet(nii,'data'),[dimOrder,4,5]));

if (xformLocal(1,xdim)<0)
    %dimFlip(xdim) = 1;
    nii = niftiSet(nii,'data',flipdim(niftiGet(nii,'data'),1));
end

if (xformLocal(2,xdim)<0)
    %dimFlip(xdim) = 2;
    nii = niftiSet(nii,'data',flipdim(niftiGet(nii,'data'),2));
end

if (xformLocal(3,xdim)<0)
    %dimFlip(xdim) = 3;
    nii = niftiSet(nii,'data',flipdim(niftiGet(nii,'data'),3));
end

%Now the permutations on the data are complete, now we can update the
%struct with the new data

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
nii = niftiSet(nii,'freqdim', dimOrder(niftiGet(nii,'freqdim')));
nii = niftiSet(nii,'phasedim', dimOrder(niftiGet(nii,'phasedim')));
nii = niftiSet(nii,'slicedim', dimOrder(niftiGet(nii,'slicedim')));

%ni.freq_dim = dimOrder(ni.freq_dim);
%else
%    disp('freq_dim not set correctly in NIFTI header.');
%end
%if(ni.phase_dim>0 && ni.phase_dim<4)
%    ni.phase_dim = dimOrder(ni.phase_dim);
%else
%    disp('phase_dim not set correctly in NIFTI header.');
%end
%if(ni.slice_dim>0 && ni.slice_dim<4)
%    ni.slice_dim = dimOrder(ni.slice_dim);
%end

return