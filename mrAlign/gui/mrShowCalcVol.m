function [curImage,inCalc] = mrShowCalcVol(samp,curImage,sampSize,volume,calc,sagSize,numSlices,x,y,dataRange,uporlo)
%
%	[curImage,inCalc] = mrShowCalcVol(samp,curImage,sampSize,volume,calc,...
%				sagSize,numSlices,x,y,dataRange,uporlo)
% PURPOSE:
%	Paint the calcarine up on the current anatomy image.
%	
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

inCalc = mrExtractImgVol(calc,sagSize,dataRange(2)-dataRange(1)+1,samp,dataRange);

if (uporlo)
	inCalc = (inCalc > 1.5);
else
	both = (inCalc > 2.5);
	inCalc = ((inCalc > 0) & (inCalc < 1.5)) | both;
end
curImage(inCalc) = -50*ones(1,sum(inCalc));

myShowImageVol(curImage,sampSize,max(curImage)*get(volslimin1,'value'),max(curImage)*get(volslimax1,'value'),x,y);



