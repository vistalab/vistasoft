function [curImage, curSize, curCrop] = mrClip (curImage, curSize,curMin,curMax);
%  MRCLIPVOL
%	mrClip(curImage, curSize,curMin,curMax)
%
%	Clips the current image and returns curImage, curSize, and curCrop (in that
% 	order).  The returned values all correspond to the cropped image. 


% Variable Declarations

nuCrop = [];
nuSize = [];

[nuCrop nuSize] = mrCrop;
curImage = cropImage(curImage,curSize,nuCrop);
curSize = nuSize;
curCrop = nuCrop;
myShowImageVol(curImage,curSize,curMin,curMax);

