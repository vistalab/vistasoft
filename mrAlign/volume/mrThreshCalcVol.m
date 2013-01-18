function [curImage,inCalc] = mrThreshCalcVol(samp,curImage,sampSize,volume,calc,sagSize,numSlices,x,y,dataRange,uporlo)
%
%	curImage = mrThreshCalcVol(samp,curImage,sampSize,volume,calc,...
%				sagSize,numSlices,x,y,dataRange,uporlo)
% PURPOSE:
%		Threshold the current correlation or antomy image
%	to show only values in the calcarine

%
% AUTHOR:  Engel
%
%

% Variable Declarations
thr = [];			% Vector of 1s and 0s.  1 means co > thresh
				% 0 means co <= thresh.  
global interpflag volslicut volslimin1 volslimax1;

if isempty(calc)
   disp ('Calcarine data is not available.');
   return
end

bareImage = mrExtractImgVol(volume,sagSize,numSlices,samp);

inCalc = mrExtractImgVol(calc,sagSize,dataRange(2)-dataRange(1)+1,samp,dataRange);

if (uporlo)
	inCalc = (inCalc > 1.5);
else
	both = (inCalc > 2.5);
	inCalc = ((inCalc > 0) & (inCalc < 1.5)) | both;
end
curImage(~inCalc) = bareImage(~inCalc);

myShowImageVol(curImage,sampSize,max(curImage)*get(volslimin1,'value'),max(curImage)*get(volslimax1,'value'),x,y);



