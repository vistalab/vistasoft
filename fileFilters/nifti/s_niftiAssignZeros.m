%% assign zeros to certain dimensions of a nifti file and save as a new nifti file
% comes in handy when we want an algorithm on a subset of the data

%% modify -- full path of the nifti
niiFile = '/sni-storage/wandell/data/reading_prf/gt/dti_qmri/dti96trilin_run1_res2/bin/wmMask.nii.gz';

% read it in
nii = niftiRead(niiFile); 

% print out dimensions of nifti
niiDims = nii.dim
niiPixDims = nii.pixdim

%%  modify -- dimensions we want to zero out
% the dimension we want to ZERO out
% increasing RAS
zeroLR = 91:187; % left
zeroPA = 81:245; % posterior 1/3rd
zeroIS = 1; 

% description for naming
descript = 'leftOccipital';

%% name of new zerofied brain mask

[pathStr, fname, ~] = fileparts(niiFile);
[~, fname, ~] = fileparts(fname);

newName = [fname '_' descript '.nii.gz']; 

%% the new data field
newData = nii.data; 
newData(zeroLR,:, :) = 0; 
newData(:,zeroPA, :) = 0; 
newData(:,:, zeroIS) = 0; 

%% make a new nifti
niiNew = nii; 
niiNew.fname = fullfile(pathStr, newName); 
niiNew.data = newData; 

writeFileNifti(niiNew)
