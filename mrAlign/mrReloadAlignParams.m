function [obX,obY,obSize,obSizeOrig,sagPts,sagSlice,lp,obPts,obSlice] = ...
              mrReloadParams(lp,curInplane,obXM,obYM,sagSize,numSlices,volume,cTheta,aTheta,curSag,reflections,scaleFac)

% PURPOSE: Implements the reloading of variables from AlignParams
% AUTHOR: SPG
% DATE: 11.21.97
% NOTES:

if ~isempty(obXM)
    obX = obXM(curInplane,:);
    obY = obYM(curInplane,:);
    lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);
else
    obX = [0,0];
    obY = [0,0];
end

[obSize,obSizeOrig] = mrFindObSize(obX,obY,sagSize,numSlices,curInplane);

[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3));





