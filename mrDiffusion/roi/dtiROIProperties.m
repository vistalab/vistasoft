function [FA,MD,radialADC,axialADC] = dtiROIProperties(dt6File, RoiFileName)
% Deprecated?? Calculate diffusion properties from an ROI
%
%   [FA, MD, radialADC, axialADC] = dtiROIProperties(dt6File, RoiFileName)
%
% There were no comments when I arrived at this file.  Not sure it is used
% much yet (BW).  Not sure how it relates to dtiGetValFromTensors.
%
%
% Compute average/range FA, MD and other properties across voxels within an
% ROI.
%
%  dt6File - Should allow dt6 data, not just the file name
%  RoiFileName - Same.  And then there are the issues of ROI coordinate
%  frame.
%
% See also: dtiGetValFromTensors
%
% 07/17/2009 ER wrote it
%
% Elena and Bob??? (c) Stanford VISTASOFT Team, 2009

%1. Get coords from ROI-- roi.coords!
load(RoiFileName);
if isempty(roi.coords)
FA(1:3)=NaN;
MD(1:3)=NaN;
radialADC(1:3)=NaN;
axialADC(1:3)=NaN;
warning('ROI is empty!');   
return
end

dt=dtiLoadDt6(dt6File); 
%2. Compute FA, MD, RD properties for ROI
[val1,val2,val3,val4,val5,val6] = dtiGetValFromTensors(dt.dt6, roi.coords, inv(dt.xformToAcpc),'dt6','nearest');
dt6 = [val1,val2,val3,val4,val5,val6];
[vec,val] = dtiEig(dt6);

[fa,md,rd,ad] = dtiComputeFA(val);

%3Return mean (across nonnan) values
FA(1)=min(fa(~isnan(fa))); FA(2)=mean(fa(~isnan(fa))); FA(3)=max(fa(~isnan(fa))); %isnan is needed  because sometimes if all the three eigenvalues are negative, the FA becomes NaN. These voxels are noisy. 
MD(1)=min(md); MD(2)=mean(md); MD(3)=max(md); 
radialADC(1)=min(rd); radialADC(2)=mean(rd); radialADC(3)=max(rd); 
axialADC(1)=min(ad); axialADC(2)=mean(ad); axialADC(3)=max(ad); 

return

%%%
%To compute FA/MD/RD/AD properties across voxels within an ROI defined in MNI
%(not individual)space as a NIFTI mask.

%1. Make ROIs from NIFTI sibparcellations (transform to individual space, too)
RoiFileName=dtiCreateRoiFromMniNifti(dt6File, mniROI_mask_file); %Group-inference-based ROI transformed into individual space
[FA,MD,radialADC,axialADC] =dtiROIProperties(dt6File, RoiFileName)
