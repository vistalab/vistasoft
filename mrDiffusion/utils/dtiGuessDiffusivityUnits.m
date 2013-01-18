function [curUnitStr,scale,newUnitStr] = dtiGuessDiffusivityUnits(md)
%
% [unitStr,scaleToStandardUnits,standardUnitStr] = dtiGuessDiffusivityUnits(meanDiffusivity)
%
% Tries to guess the diffusivity units based on the range of values in the
% meanDiffusivity volume data. You can also pass in a dt6 array and the
% mean diffusivity will be computed internally.
%
% The algorithm assumes this is water diffusion in tissue at a temperature
% somewhere near 37 deg C (self-diffusion of water is ~3 um^2/msec at 37
% deg C)
%
% Multiplying the dt6 values by scaleToStandardUnits will convert the units
% to micron^2/msec, which is also returned in 'standardUnitStr'.
%
% HISTORY:
% 2007.04.19 RFD: wrote it.

if(ndims(md)==4&&size(md,4)>=3)
    md = mean(md(:,:,:,1:3),4);
elseif(ndims(md)~=3)
    error('meanDiffisivity must be a 3d mean diffusivity volue or a 4d dt6 array.');
end
newUnitStr = 'um^2/msec';
avgMd = median(md(md(:)>0));
if(avgMd>1e-10&&avgMd<1e-8)
    scale = 1e9;
    curUnitStr = 'm^2/sec';
elseif(avgMd>1e-4&&avgMd<1e-2)
    scale = 1e3;
    curUnitStr = 'mm^2/sec';
elseif(avgMd>1e2&&avgMd<1e4)
    scale = 1e-3;
    curUnitStr = 'um^2/sec';
elseif(avgMd>0.1&&avgMd<10)
    scale = 1;
    curUnitStr = 'um^2/msec';
else
    scale = 1;
    curUnitStr = 'unknown';
    newUnitStr = 'unknown';
end
return
