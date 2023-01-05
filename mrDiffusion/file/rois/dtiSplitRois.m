function [imgLabel,roisimgLabels] =dtiSplitRois(img, minImgValue, minClusterSize)

%Find blobs (on minClusterSize -- in num voxels or greater) in a thresholded image.
%Return an image which is a mask with blobs coded by different imtegers. 

%ER 10/2009 wrote it 

if ~exist('minImgValue', 'var') || isempty(minImgValue)
minImgValue=min(img(:)); 
end
if ~exist('minClusterSize', 'var') || isempty(minClusterSize)
minClusterSize=1;
end

mask=img>minImgValue;


        % Find all the objects (separate clusters of 26-connected voxels)
        [imgLabel,numObjects] = bwlabeln(mask, 26);


        % Remove clusters smaller than minClusterSize
            [imgHist,labelNum] = hist(imgLabel(imgLabel(:)>0),1:numObjects);
            roisimgLabels= labelNum(find(imgHist>=minClusterSize));
            imgLabel(~ismember( imgLabel, roisimgLabels))=0; 
return;

%To transform an image file to a file with blobs use
a=niftiRead('dmn.nii.gz'); 
[roisimg, labels]=dtiSplitRois(a.data, 5, 1.96);
a.data=roisimg;
a.fname='dmn_blobs.nii.gz'; 
writeFileNifti(a); 

%See dtiLoadROIsfromNifti which  uses current function to load ROIs from the
%integer-coded MNI blob file. 
