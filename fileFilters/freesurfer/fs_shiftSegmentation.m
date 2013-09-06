function fs_shiftSegmentation(segImage, outImage,shiftsize)

% This will open a segmentation image file (or any image for that
% matter), That image will be shifted the desired number of voxels in the x
% y and z directions and then a new nifti image will be saved.
%
%  Inputs:
%  segImage:    Path to t1_class.nii.gz
%  outImage:    Path and name of image to save
%  shiftsize:   A vector with 3 entries.  Each entry is the amount of shift
%  in the x, y or z dimension
%
%  Example:  segImage='/biac2/wandell2/t1_class.nii.gz'
%            outImage='/biac2/wandell2/t1_class_man.nii.gz'
%            shiftsize=[1 0 -1]
%            fs_shiftSegmentation(segImage, outImage,shiftsize)

% read in the segmentation nifit file
im=niftiRead(segImage);

% shift the data in the file
im.data=circshift(im.data,shiftsize);

% Name the image by the user input
im.fname=outImage;

fprintf('\nWriting new image %s\n',outImage);

% save the new nifti image
writeFileNifti(segImage);
