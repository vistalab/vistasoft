function calc = mrInitCalcVol(sagSize,sagCrop,dataRange)
%
% MRINITCALCVOL
%
%   calc = mrInitCalcVol(sagSize,sagCrop,dataRange)
%	Initializes a volume of calcarine data reading headerless image files.
%	The images are 256x256x2bytes
%	dataRange is the range of sagittal slices for which there is calcarine


oSize = [256 256];
header = 0;		

calcdir = input('Full pathname for calcarine data?','s');
calc = mySeries( calcdir,dataRange(1):dataRange(2), oSize, sagCrop, header);
calc = reshape(calc',1,prod(size(calc)));
save calc calc sagCrop sagSize dataRange



