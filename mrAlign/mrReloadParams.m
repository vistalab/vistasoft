function [obX,obY,obSize,obSizeOrig,sagPts,sagSlice,lp,obPts,obSlice] = ...
              mrReloadParams(lp,curInplane,obXM,obYM,sagSize,numSlices,volume,cTheta,aTheta,curSag,reflections,scaleFac)

% PURPOSE: Implements the reloading of variables from AlignParams
% AUTHOR: SPG
% DATE: 11.21.97
% NOTES: Needed to put this in a function for the conditional. Fixes the bug
% that comes up when alignments without inplanes setup are reloaded. Reloading
% alignments with inplanes still does not refresh the inplanes automatically...

if (curInplane ~= 0)
    obX = obXM(curInplane,:);
    obY = obYM(curInplane,:);
else
    obX = [0,0];
    obY = [0,0];
end

[obSize,obSizeOrig] = mrFindObSize(obX,obY,sagSize,numSlices,curInplane);

[sagSlice,sagPts,obSlice,obPts]=mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,1,1/scaleFac(1,3),curInplane);


% this isn't working in its usual mystical way

if (curInplane ~= 0)
   lp = mrRefreshInplanes(lp,obXM,obYM,curInplane,0);
end



