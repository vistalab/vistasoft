function borderCoordsRoi=dtiFindBorderBetweenRois(roi1_img, roi2_img, dt6File, minDist, borderRoiName)
%Find a shared border separating two ROIs
%
% borderCoords=dtiFindBorderBetweenRois(roi1_img, roi2_img, dt6File, [minDist=1.87])
%
% Given two nifti images with ROIs, find a set of points where the two 
% ROIs are touching within the distance set by minDist parameter. 
%
% Example: 
%        dt6File=fullfile(pathtoChild, 'dt6.mat');
%        roi1_img=fullfile(pathtoChildInFreesurfer, 'aparc_aseg1015.nii');
%        roi2_img=fullfile(pathtoChildInFreesurfer, 'aparc_aseg1030.nii');
%        borderCoordsRoi=dtiFindBorderBetweenRois(roi1_img, roi2_img, dt6File, 5, borderRoiName);
%        borderCoordsRoiFile=fullfile(pathtoChild, 'ROIs', 'border1015to1030'); 
%        borderRoiName='borderRoi1toRoi2'; 
%        dtiWriteRoi(borderCoordsRoi, borderCoordsRoiFile); 
% 
% (c) Vistalab

% HISTORY: 
% 03/2010 ER wrote it

if ~exist('minDist', 'var') || isempty(minDist)
minDist=1.87; %mm
end

roi1=dtiImportRoiFromNifti(roi1_img, dt6File); 
roi2=dtiImportRoiFromNifti(roi2_img, dt6File); 

[indices, bestSq]=nearpoints(roi1.coords', roi2.coords'); 
borderCoords=(roi1.coords(bestSq<(minDist^2), :)+roi2.coords(indices(bestSq<(minDist^2)), :))./2; 
borderCoordsRoi=dtiNewRoi(borderRoiName, [], borderCoords); 