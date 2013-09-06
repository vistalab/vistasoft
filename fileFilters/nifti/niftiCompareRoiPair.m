function v = niftiCompareRoiPair(roi1,roi1LabelVal,roi2,roi2LabelVal)
% 
% function v = niftiCompareRoiPair(roi1,roi1LabelVal,roi2,roi2LabelVal)
% 
% This function takes two nifti ROIs and computes volume and a measure of
% overlap (percent agreement) as a means of evaluating reliabitliy in the
% case of two raters drawing the same ROI. The roi.pixdim field is used to
% compute the volume appropriately. 
% 
% EXAMPLE USAGE:
% v = niftiCompareRoiPair('r1c.nii.gz',1,'r2c.nii.gz',3);
% v = 
%         roi1Name: 'r1c.nii.gz'
%          roi1Val: 1
%         roi2Name: 'r2c.nii.gz'
%          roi2Val: 3
%            units: 'mm^3'
%              dim: [1 1 1]
%       roi1Volume: 5265
%       roi2Volume: 4996
%       overlapVol: 4868
%       overlayVol: 5393
%     percentAgree: 90.2652%
% 
% HISTORY
% 2011.06.01 LMP: wrote it.
% 2011.06.03 LMP: now calls for a label value for each roi. This allows
%            files with multiple labels to be used. User must specify the 
%            value of each. Now uses the dim of the roi itself to calculate
%            the volume.

%% 

% Check input arguments and prompt for them if they don't exist
if(~exist('roi1','var') || isempty(roi1))
  dd = pwd; roi1 = mrvSelectFile([],'*.nii.gz','Select ROI 1 File',dd);
end

if(~exist('roi1LabelVal','var')) || isempty(roi1LabelVal)
    roi1LabelVal = str2double(inputdlg('Enter ROI1 Label Value','ROI 1 Label Value'));
end

if(~exist('roi2','var') || isempty(roi2))
  dd = pwd; roi2 = mrvSelectFile([],'*.nii.gz','Select ROI 2 File',dd);
end

if(~exist('roi2LabelVal','var')) || isempty(roi2LabelVal)
    roi2LabelVal = str2double(inputdlg('Enter ROI2 Label Value','ROI 2 Label Value'));
end

% Read in the nifti files
roi1 = niftiRead(roi1);
roi2 = niftiRead(roi2);
if roi1.pixdim==roi1.pixdim
    mmPerVoxel = roi1.pixdim; % Dimensions of the t1 image
else error('ROI dimensions must agree');
end

% Find the points in the data array that make up the ROI
r1Inds = find(roi1.data==roi1LabelVal); % points in roi1 where there is any label >0
r2Inds = find(roi2.data==roi2LabelVal); % points in roi2 where there is any label >0
a = r1Inds(:,1); 
b = r2Inds(:,1);
c = ismember(a,b); % Find the overlap indices

% Get the inds of the overlay ROI - that is the ROI that would be created
% if you overlay and combine the two ROIs together (with the overlap only
% being counted once)
d = vertcat(a,b);
e = unique(d); % Overlay indices

% Populate the structure
v.roi1Name = roi1.fname;
v.roi1Val  = roi1LabelVal;
v.roi2Name = roi2.fname;
v.roi2Val  = roi2LabelVal;
v.units = 'mm^3';
v.dim = roi1.pixdim;

% Calculate the volume and percent agreement
v.roi1Volume = length(a)*prod(mmPerVoxel);
v.roi2Volume = length(b)*prod(mmPerVoxel);
v.overlapVol = sum(c)*prod(mmPerVoxel);
v.overlayVol = length(e)*prod(mmPerVoxel);
v.percentAgree = v.overlapVol/v.overlayVol*100;


% Print the results to the screen
fprintf('\n================================\n');
% fprintf('T1 Image        = %s\n',v.imgName);
fprintf('ROI1 Name       = %s\n',v.roi1Name);
fprintf('ROI1 Label Val  = %s\n',num2str(roi1LabelVal));
fprintf('ROI2 Name       = %s\n',v.roi2Name);
fprintf('ROI2 Label Val  = %s\n',num2str(roi2LabelVal));
fprintf('Units           = %s\n',v.units);
fprintf('Voxel Dim       = %s\n',num2str(v.dim));
fprintf('Roi1 Volume     = %s\n',num2str(v.roi1Volume));
fprintf('Roi2 Volume     = %s\n',num2str(v.roi2Volume));
fprintf('Overlap Volume  = %s\n',num2str(v.overlapVol));
fprintf('Overlay Volume  = %s\n',num2str(v.overlayVol));
fprintf('Percent Agree   = %s\n',num2str(v.percentAgree));
fprintf('================================\n');

return




