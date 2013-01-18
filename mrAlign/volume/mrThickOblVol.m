slice = function mrThickOblVol(thick,obX,obY,volume,sagSize,numSlices,reflections,aTheta,cTheta,curSag);
% OBSOLETE
%
% mrThickOblVol(thick,obX,obY,volume,sagSize,numSlices,reflections
%                                    ,aTheta,cTheta,curSag);
%
% Places an averaged oblique image in the oblique window.
% POIRSON 08.09.96 Added reflection logic
% SPG 12.15.96 Replaced old oblique slice function calls. removed
%   reflection calls. they are covered by mrRotSagVol.

global obwin volslimin2 volslimax2

numextracts = 10;

if(obX(1) <= sagSize(2) & obY(1) <= sagSize(1) & obX(1) > 0 & obY(1) > 0 & ...
   obX(2) <= sagSize(2) & obY(2) <= sagSize(1) & obX(2) > 0 & obY(2) > 0 )

  d = sqrt((obY(2)-obY(1)).^2 + (obX(2)-obX(1)).^2); 
  unitv = [(obX(2)-obX(1))/d, (obY(2)-obY(1))/d];
  perp = [-unitv(2), unitv(1)];
  obSize = mrFindObSize(obX,obY,sagSize,numSlices);
  
  newX = obX-perp(1)*(thick/2);
  newY = obY-perp(2)*(thick/2); 
  
  for i = 1:numextracts
	newX = newX+perp(1)*(thick/numextracts);
	newY = newY+perp(2)*(thick/numextracts);
	[sagSlice,sagPts,temp,obPts] = mrRotSagVol(volume,newX,newY,obSize,sagSize,cTheta,aTheta,curSag,reflections,0);
        obSlices(i,:) = temp;
  end
	slice = mean(obSlices);
   
else
	
  error('Oblique points out of range. Re-Clip inplanes grid.');
end

  
 




