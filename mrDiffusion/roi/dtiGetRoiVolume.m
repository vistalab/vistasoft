function v = dtiGetRoiVolume(roi,t1,dt)
%
% function v = dtiGetRoiVolume(roi,t1,dt)
%
% This function will take a given roi and compute the volume against the t1
% nifti. The function returns a structure (v) which contains:
% v.subjectName, v.roiName, v.imgName, v.volume (the volume without units),
% and v.units (the volume units).
%
% History:
% 05/15/2009 LMP wrote the thing. Code modified from dtiFiberUI.
%

if(~exist('roi','var') || isempty(roi))
  dd = pwd;
  roi = dtiReadRoi(mrvSelectFile([],'*.mat','Select ROI File',dd));
end
if(~exist('t1','var') || isempty(t1))
  dd = pwd;
  t1 = niftiRead(mrvSelectFile([],'*.nii.gz','Select T1 Nifti',dd));
end
if(~exist('dt','var') || isempty(t1))
  dd = pwd;
  dt = dtiLoadDt6(mrvSelectFile([],'*.mat','Select DT6 File',dd));
end

v.subjectName = dt.subName;
v.roiName = roi.name;
v.imgName = t1.fname;

anat = double(t1.data);
mmPerVoxel = t1.pixdim;
xform = t1.qto_xyz;
coords = roi.coords;

ic = mrAnatXformCoords(inv(xform), coords);
ic = unique(ceil(ic),'rows');
sz = size(anat);
imgIndices = sub2ind(sz(1:3), ic(:,1), ic(:,2), ic(:,3));
n = length(imgIndices);
v.volume = n*prod(mmPerVoxel);
v.units = 'mm^3';

return


