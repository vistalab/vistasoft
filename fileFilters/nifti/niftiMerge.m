function niiMerged = niftiMerge(listNiftis, niiMergedName)
% For a cell array of nifti paths, create a new nifti that is the union of
% all niftis in listNiftis. Useful for combining nifti ROIs.
% The data field of all the niftis in listNiftis must 
% have the same dimension. 
% The union operation is applied to the data. The output will be a binary 
% matrix; the input need not be binary. 

% Ex: 
% listNiftis = {
%     '/biac4/wandell/data/anatomy/HCP_100307/ROIsNiftis/LGN_left.nii.gz'
%     '/biac4/wandell/data/anatomy/HCP_100307/ROIsNiftis/LGN_right.nii.gz'
% }
%
% niiMergedName =
% '/biac4/wandell/data/anatomy/HCP_100307/ROIsNiftis/LGN.nii.gz';
%
% niiLGN = niftiMerge(listNiftis, niiMergedName); 
% writeFileNifti(niiLGN)
%
% RL, 10/2016
%
%% Template nifti
nii = readFileNifti(listNiftis{1}); 

%% initialize the new nifti 

niiMerged = nii; 

% class of the data
strClass = class(nii.data); 

% give the new nifti a data field of all zeros 
newData = zeros(size(nii.data)); 

% name of merged nifti
niiMerged.fname = niiMergedName; 


%% loop over niftis
% number of niftis to comebine
numNiftis = length(listNiftis); 

for jj = 1:numNiftis
   
    % current nifti in the list
    niiTem = readFileNifti(listNiftis{jj}); 

    % anything that is nonzero in listNiftis is assigned a 1
    newData = niiTem.data | newData; 
     
end

%% the new nifti
% have the data be the same class as the original
eval(['newData = ' strClass '(newData);']);

% reassign the data
niiMerged.data = newData; 

% save the data
writeFileNifti(niiMerged);

end