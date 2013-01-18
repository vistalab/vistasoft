function [obSize,obSizeOrig] = mrFindObSize(obX,obY,sagSize,numSlices,curInplane)

% AUTHOR: Sunil Gandhi
% DATE: 11.1.96
% FUNCTION:
%     determines the olbique slice size. Adds in a horizontal buffer of 
%     BUFFSIZE, half on one side, half on the other so that oblique slices
%     actually span from -BUFFSIZE/2 to numSlices+BUFFSIZE/2. So, when the
%     sagittal plane rotates, one side of the oblique gets rotated into out-
%     of-range coordinates, while points from the other side once invalid
%     now get rotated into valid coordinates. Now for point selection the
%     original dimensions are needed. So note that in mrLoadVol.m, the
%     variable obSizeOrig contains this original information. 

if(obX(1) <= sagSize(2) & obY(1) <= sagSize(1) & obX(1) > 0 & obY(1) > 0 & ...
   obX(2) <= sagSize(2) & obY(2) <= sagSize(1) & obX(2) > 0 & obY(2) > 0 ) 

  BUFFSIZE = 10;

  d = sqrt((obY(2)-obY(1)).^2 + (obX(2)-obX(1)).^2); 

  obSizeOrig = [ceil(d),numSlices];
  obSize = [ceil(d),numSlices + BUFFSIZE]; 
else
  if (curInplane ~=0)
     error('Oblique points out of range. Re-Clip inplanes grid.');
  end

  % always set returned parameters to something
  obSizeOrig = [];
  obSize = [];

end










