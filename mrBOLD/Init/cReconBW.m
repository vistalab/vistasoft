function [magTS, phaseTS] = cReconBW(fName, slice)

% [magTS, phaseTS] = cReconBW(fName, slice);
%
% Perform a complex recon using Alex Wade's tstrecon code.
% Returns pair of single-slice time-series arrays of size: 
% ny x nx x nFrames -- magTS is magnitude and phaseTS is
% phase. Time-duration and spatial cropping are performed,
% but no trend removal. Inputs are pFile name [fName], and
% slice index [slice]. Assumes pwd points to valid session
% directory, and uses global mrSESSION.
%
% DBR 8/00

global mrSESSION

% Do recon, extract complex time series:
cTS = tstrecon3Tb([], fName, slice, slice);
cTS = cTS{1}';

% Remove junk frames:
f0 = mrSESSION.junkFirstFrames+1;
nFrames = mrSESSION.nFrames;
fEnd = f0 + nFrames - 1;
cTS = cTS(f0:fEnd, :);

% Crop:
cTS = reshape(cTS, [nFrames, mrSESSION.fullSize]); % reshape the array to full size
x0 = mrSESSION.tseriesCrop(1, 1);
xN = mrSESSION.tseriesCrop(2, 1);
y0 = mrSESSION.tseriesCrop(1, 2);
yN = mrSESSION.tseriesCrop(2, 2);
cTS = cTS(:, y0:yN, x0:xN);

%Shuffle to standard t-series shape:
cTS = reshape(cTS, nFrames, (yN-y0+1)*(xN-x0+1));
      
% Get magnitude and phase:
magTS = abs(cTS);
phaseTS = angle(cTS);
   