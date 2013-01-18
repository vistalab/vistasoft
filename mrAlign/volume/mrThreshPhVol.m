function [curImage,phImage] = mrThreshPhVol(samp,sampSize,volco,volph,volume,sagSize,numSlices,x,y,dataRange)
%
%
% PURPOSE:
%   Compute an image whose pixel values show the best phase angle of
%   the time series at each image point.
%   
%
% AUTHOR:  Engel
%
%

% Variable Declarations
thr = [];			% Vector of 1s and 0s.  1 means co > thresh
				% 0 means co <= thresh.  
global interpflag volslicut volslimin1 volslimax1;

if isempty(volco)
   disp ('Correlation data is not available.');
   return
end

if (interpflag)
	sinIm = mrExtractImgVol(sin(volph),sagSize,dataRange(2)-dataRange(1)+1,samp,dataRange);
	cosIm = mrExtractImgVol(cos(volph),sagSize,dataRange(2)-dataRange(1)+1,samp,dataRange);
	phImage = atan2(sinIm,cosIm);
else
	phImage = mrExtractImgVol(volph,sagSize,dataRange(2)-dataRange(1)+1,samp,dataRange);
end
phImage = phImage;

curImage = mrExtractImgVol(volume,sagSize,numSlices,samp);

co = mrExtractImgVol(volco,sagSize,dataRange(2)-dataRange(1)+1,samp,dataRange);

cutoff = get(volslicut,'value');
disp(['Cutoff = ',num2str(cutoff)]);
thr = co > cutoff;
curImage(thr) = -((phImage(thr)+pi)/(2*pi)*110);	%Scale negatives for colors

myShowImageVol(curImage,sampSize,max(curImage)*get(volslimin1,'value'),max(curImage)*get(volslimax1,'value'),x,y);






