function dtiConvertFreeSurferRoiToMat(roiIm,roiNum,outname)

%roiIm:  is a path to the free surfer segmentation image in nifti format which is usually
%        called aparc_aseg.nii.
%roiNum: So each cortical region is represented by a particular number in
%        the image array.  This input is the number that you want turned into an
%        ROI
%outname:the name of the output file.

%% load in image

im=niftiRead(roiIm);

%now we want to convert the image to a list of coordinates in acpc space
%find roi index locations

ndx=find(im.data==roiNum);

%convert to ijk coords

[I J K]=ind2sub(size(im.data),ndx);

%convert to acpc coords
acpcCoords=mrAnatXformCoords(im.qto_xyz, [I J K]);

%now put these coordinates into the mrDiffusion roi structure

roi=dtiNewRoi(outname,'r',acpcCoords);

%save out the roi
pathstr=fileparts(roiIm);

dtiWriteRoi(roi,fullfile(pathstr,outname));
fprintf('\nwriting file %s\n',fullfile(pathstr,outname));

return
