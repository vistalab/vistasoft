function outNii = niftiAssignZeros(nii, saveDir, niiNewName, keepLR, keepPA, keepIS)
% outNii = niftiAssignZeros(nii, newName, keepLR, keepPA, keepIS)
%
% This function writes and saves a new nifti where specified dimensions of
% the data are overwritten with zeros. Useful for unit testing.
%
% Outputs
    % outNii: the new nifti file (in the form of readFileNifti) 
%
% Inputs
    % nii: the nifti file to be copied, and an output of readFileNifti
    % saveDir: where the new nifti should be written
    % niiNewName: name of the new nifti file 
    % keepLR: the dimensions we want to keep in the 1st dimension 
    % keepPA: the dimensions we want to keep in the 2nd dimension
    % keepIS: the dimensions we want to keep in the 3rd dimension

%% the original nifti
niiDims = nii.dim;
   
%% the dimension we want to ZERO out
zeroLR = setdiff(1:niiDims(1), keepLR);
zeroPA = setdiff(1:niiDims(2), keepPA);
zeroIS = setdiff(1:niiDims(3), keepIS); 

% volume of the original and the cropped
vol = prod(niiDims); 
volCropped = length(keepLR) * length(keepPA) * length(keepIS);

% the fraction of the cropped to the original
% print out 
fracCrop = volCropped/vol;
display(['The cropped volume is ' num2str(fracCrop) ' of the original. '])

%% the new data field
newData = nii.data; 
newData(zeroLR,:, :) = 0; 
newData(:,zeroPA, :) = 0; 
newData(:,:, zeroIS) = 0; 

%% make a new nifti
outNii = nii; 
outNii.fname = fullfile(saveDir, niiNewName); 
outNii.data = newData; 

writeFileNifti(outNii)

end