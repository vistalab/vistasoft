function niftiOutput=niftiBlobify(niftiInput, minImgValue, minClusterSize, niftiOutput)

%%A wrapper for dtiSplitROIs. Find blobs (on minClusterSize -- in num voxels or greater) in a thresholded image.
%Save as an image which is a mask with blobs coded by different imtegers. 

%niftiOutput=[niftiInput(1:end-7) 'thr'  num2str(minImgValue) 'cluster' num2str(minClusterSize) '.nii.gz'];

%ER 11/2009 wrote it 
if ~exist('niftiOutput', 'var') || isempty(niftiOutput)
niftiOutput=[niftiInput(1:end-7) 'thr'  num2str(minImgValue) 'cluster' num2str(minClusterSize) '.nii.gz'];
end


a=niftiRead(niftiInput); 
[roisimg]=dtiSplitRois(a.data, minImgValue, minClusterSize); 
a.data=roisimg;
a.fname= niftiOutput;
writeFileNifti(a); 
