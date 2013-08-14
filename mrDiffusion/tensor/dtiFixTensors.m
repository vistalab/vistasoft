function dtiFixTensors(tensorFile, outFile)
%
% dtiFixTensors(tensorFile, [outFile=tensorFile])
%
% Simple linear tensor fits sometimes produce non-positive-definite
% matrices- tensors that have negative eigenvalues due to noise in the raw
% diffusion data. Some of these voxels with negative eigenvalues are in the
% white matter, ususally in regions of very high anisotropy (like the
% corpus callosum). This function will fix all voxels with negative
% eigenvlaues by clipping all eigenvalues to 0 and writing the new tensors
% to the tensors NIFTI file.
%
% E.g.:
% dtiFixTensors('.../dti06/bin/tensors.nii.gz');
%
% 2007.02.27 RFD wrote it.
% 2008.03.12 RFD: modified code to avoid precision problems where 'fixed'
% tensors would still produce negative eigenvalues. We now threshold based
% on a minVal of 1e-6 rather than exactly 0.

% Note: the following might need to be changed if tensors are not in the
% standard 0-5 range of diffusion values (ie. units are something other
% than microns^2/msec)
minVal = 1e-6;

ni = niftiRead(tensorFile);
dt6 = double(squeeze(ni.data(:,:,:,1,[1 3 6 2 4 5])));
[eigVec,eigVal] = dtiEig(dt6);
mask = repmat(all(eigVal==0,4),[1 1 1 3]);
eigVal(eigVal<minVal) = minVal;
eigVal(mask) = 0;
clear mask;
dt6 = dtiEigComp(eigVec,eigVal);
ni.data = dt6(:,:,:,[1 4 2 5 6 3]);
sz = size(ni.data);
ni.data = reshape(ni.data,[sz(1:3),1,sz(4)]);
if(exist('outFile','var')&&~isempty(outFile))
    ni.fname = outFile;
end
writeFileNifti(ni);

return;
