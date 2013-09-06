function [meanValIm means sds roiVals]=dtiImageValsFromTemplateROIs(imPath,tmpPath)
% Inputs:
% imPath    = a cell array of paths to image files
% tmpPath   = is a cell array of paths to template files
%
% If these paths are not set then it will default to the paths for HLF
% project
%
% Outputs:
% meanValIm = the mean values for the group within each roi of the template
%             image.  Values are assigned to the template image of the last 
%             subject
% means     = the group means for image values in each ROI in the template
% sds       = the group standard deviation for each ROI in the template
% roiVals   = the values in the template image associated with each of the
%             means.  In other words which roi each mean corresponds to in 
%             case numbering is not continuous

if ~exist('imPath','var') || isempty(imPath)
imPath={'/biac3/wandell5/data/relaxometry/HLF15T15mm/am1_5T_1_5mms/HLFB1.nii.gz'...
    '/biac3/wandell5/data/relaxometry/HLF15T15mm/rb1_5T_1_5mms/HLFB1.nii.gz'...
    '/biac3/wandell5/data/relaxometry/HLF15T15mm/rfd1_5T_1_5mms/HLFB1.nii.gz'};
end
if ~exist('tmpPath','var') || isempty(tmpPath)
tmpPath={'/biac3/wandell4/data/reading_longitude/dti_adults/freesurfer/am090121/mri/aparc+aseg.nii.gz'...
    '/biac3/wandell4/data/reading_longitude/dti_adults/freesurfer/rb080930/mri/aparc+aseg.nii.gz'...
    '/biac3/wandell4/data/reading_longitude/dti_adults/freesurfer/rfd080930/mri/aparc+aseg.nii.gz'};
end


for jj=1:length(imPath)
    %Read Image
    im=niftiRead(imPath{jj});
    %Read ROIs from nifti
    tmp=niftiRead(tmpPath{jj});
    %reslice image to match template dimensions
    [newImg,xformImg] = mrAnatResliceSpm(im.data, inv(im.qto_xyz), [], [1 1 1],[7 7 7 0 0 0],0);
    [newTmp,xformTmp] = mrAnatResliceSpm(tmp.data, inv(tmp.qto_xyz), [], [1 1 1], [0 0 0 0 0 0], 0);
    %Each ROI within the template is signified by a unique value.
    roiVals=unique(newTmp(:));
    %calculate stats for each ROI in the templat
    for ii=1:length(roiVals)
        stats(jj,roiVals(ii)+1)=mean(newImg(newTmp==roiVals(ii)));
    end
end

%plot means and SDs
figure
means=mean(stats(:,mean(stats)>0));
sds=std(stats(:,mean(stats)>0));
errorbar(means,sds./2);
%make an image where regions are given mean HLF values
meanValIm=tmp;
for ii=1:length(roiVals)
    meanValIm.data(meanValIm.data==roiVals(ii))=means(ii);
end
%clip white matter values
meanValIm.data(meanValIm.data>.1)=nan;
%clip csf values
meanValIm.data(meanValIm.data<.02)=nan;
meanValIm.fname='MeanValsInFreeSurfROIs.nii.gz';
showMontage(meanValIm.data, 75:10:155,jet(256));
    
