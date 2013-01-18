function curImage = mrThreshCorVol(samp,sampSize,volco,volume,sagSize,numSlices,x,y,dataRange)
%
% mrThreshCorVol
%
%
%	Display the volume anatomy covered w/thresholded correlations
%	Test. 

global volslimin1 volslimax1 volslicut;

% Variable Declarations
thr = [];			% Matrix of 1s and 0s.  1 means co > thresh
				% 0 means co <= thresh.  
if isempty(volco)
   disp ('Correlation data is not available.');
   return
end

curImage = mrExtractImgVol(volume,sagSize,numSlices,samp);
co = mrExtractImgVol(volco,sagSize,dataRange(2)-dataRange(1)+1,samp,dataRange);

cutoff = get(volslicut,'value');
disp(['Cutoff = ',num2str(cutoff)]);

thr = co > cutoff; 			    % compare correlation to threshold
curImage(thr) = -1*ones(1,sum(thr));           %"-1"s are turned green
myShowImageVol(curImage,sampSize,max(curImage)*get(volslimin1,'value'),max(curImage)*get(volslimax1,'value'),x,y);
