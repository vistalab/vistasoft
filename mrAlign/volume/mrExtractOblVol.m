function [obPts,obSize] = mrExtractOblVol(obX,obY,sagSize,numSlices)
%
% MREXTRACTOBLVOL
%
% 	[obPts,obSize] = mrExtractOblVol(obX,obY,sagSize,numSlices)
%
%	Returns points to be used as indices into volume data coresponding to
%	the oblique slice specified in obX, obY.
%

if(obX(1) <= sagSize(2) & obY(1) <= sagSize(1) & obX(1) > 0 & obY(1) > 0 & ...
   obX(2) <= sagSize(2) & obY(2) <= sagSize(1) & obX(2) > 0 & obY(2) > 0 )

  d = sqrt((obY(2)-obY(1)).^2 + (obX(2)-obX(1)).^2); 
  unitv = [(obX(2)-obX(1))/d, (obY(2)-obY(1))/d];

  x = obX(1); y = obY(1); 
  for i = 0:round(d);
	  a = x+i*unitv(1); b = y+i*unitv(2);
 	  tmp(i+1,:) = [a,b,1];
  end

  for i = 1:numSlices
	tmp(:,3) = i*ones(length(tmp),1);
	obPts = [obPts;tmp];
  end

  obSize = [round(d)+1,numSlices]; 
else
  error('Oblique points out of range. Re-Clip inplanes grid.');
end


