function [sagSlice,sagPts,cTheta,aTheta,obSlice,obPts]= mrRotSagVol2(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,axis,sagDelta,curSag,reflections,thick,curInplane)

% AUTHOR:  Sunil Gandhi
% DATE:    11.5.96
% FUNCTION: wrapper function for slice rotation, hence the suffix. takes
% care of the updating  of the globals cTheta and aTheta by determining
% which axis the current rotation calls for.


global coronal;

 if axis == coronal
  cTheta = cTheta+sagDelta;
 else
  aTheta = aTheta+sagDelta;
 end

 
 [sagSlice,sagPts,obSlice,obPts] = mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,thick,curInplane);
 





