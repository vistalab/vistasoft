function v = niftiRoiVolume(roi,printScreenFlag)
% Calculates the volume of a nifti ROI mask
%
%  v = niftiRoiVolume(roi,[printToScreenFlag])
% 
% This function calculates the volume of a nifti ROI mask and returns it to
% the user in a structure (v) along with a few other things (see example).
% The pixdim field of the roi nifti structure is used to compute the
% volume. [printToScreenFlag] can be any logical scalar value (1 = yes,
% 0=no). For nifti files with multiple label values the volumes for each
% label are returned in v.volume(n) where n= the label number. For example,
% if you want the volume for label 3 (left white matter) it is v.volume(3).
% 
% EXAMPLE USAGE:
% v = niftiRoiVolume('r3.nii.gz')
% v = 
%     roiName: 'r3.nii.gz'
%      volume: [5265 5743]
%         dim: [1 1 1]
%       units: 'mm^3'
%
% HISTORY
% 2011.06.01 LMP - wrote it.
% 2011.06.03 LMP - Now supports a nifti roi file with multiple labels. The
%                  label val will be placed in v.volume(n) where n=label val.

%% 

% Check input arguments and prompt for them if they don't exist
if(~exist('roi','var') || isempty(roi))
  dd = pwd; roi = mrvSelectFile([],'*.nii.gz','Select ROI File',dd);
end

% Read in the nifti file
roi = niftiRead(roi);
mmPerVoxel = roi.pixdim; % Dimensions of the t1 image
v.roiName = roi.fname;

% Find the points in the data array that make up the ROI
u = unique(roi.data);
inds = find(u>0); 
for ii=1:numel(inds)
    a = find(roi.data==u(inds(ii)));
    % Calculate the volume and put in the structure
    v.volume(u(inds(ii))) = length(a)*prod(mmPerVoxel);
end
v.dim     = roi.pixdim;
v.units   = 'mm^3';

if exist('printScreenFlag','var') && printScreenFlag ~=0
    % Print the results to the screen
    fprintf('\n================================\n');
    fprintf('ROI1 Name  = %s\n',v.roiName);
    fprintf('Roi Volume = %s\n',num2str(v.volume));
    fprintf('Voxel Dim  = %s\n',num2str(v.dim));
    fprintf('Units      = %s\n',v.units);
    fprintf('==================================\n');
end

return




