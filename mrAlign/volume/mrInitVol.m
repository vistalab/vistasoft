function [volume, sagSlice, sagSize, curSag] = mrInitVol(voldir,sagSize,sagCrop,numSlices)
%
% MRINITVOL
%     [volume, sagSlice, sagSize, curSag] = mrInitVol(voldir,sagSize,sagCrop,numSlices)
%
%	Initializes the volume anatomy MRI data, reading the signa image files.
%

oSize = [256 256];
header = 1;		

volume = mySeries( [voldir,'/anatomy/volume'],[1:numSlices], oSize, sagCrop, header);
volume = reshape(volume',1,prod(size(volume)));
save volume volume sagCrop sagSize numSlices

curSag = floor(numSlices/2);
mrShowSagVol(volume,sagSize,curSag,[]);


