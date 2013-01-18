function [sagSlice, sagSize] = mrViewVol(voldir)
% 
% MRVIEWVOL  [sagSlice, sagSize] = mrViewVol(voldir)
%
%	View a single slice from the volume anatomy so that it can be clipped...
%
%
global volslimin1 volslimax1;

sagSize = [256 256]; 			% Size of images
header = 1;				% Header is present

sagSlice = myRead([voldir,'/anatomy/volume/I.030'],sagSize,header);  % Just pick one
sagMin = min(sagSlice);
sagMax = max(sagSlice);
set(volslimin1,'Value',0);
set(volslimax1,'Value',1);
myShowImageVol(sagSlice,sagSize,sagMin,sagMax);


