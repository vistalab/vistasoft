function [aTS, bTS] = cRecon1(scanParams, fName, slice, compFlag, rotFlag, shifts)

% [aTS, bTS] = cRecon1(scanParams, fName, slice, compFlag, shifts);
%
% Load and crop complex recon data.
% Returns pair of single-slice time-series arrays of size: 
% ny x nx x nFrames -- aTS is real and bTS is imaginary;
% the latter is returned only if the optional compFlag
% input is set. Time-duration and spatial cropping are performed,
% but no trend removal. Inputs are pFile name [fName], and
% slice index [slice]. Optional input rotFlag performs a 90
% degree rotation to make functional images match inplanes;
% use MakeMovie.m or similar to check if necessary. Optional
% input shifts allows correction of fallback errors or similar.
% Assumes pwd points to valid session
% directory, and uses global mrSESSION.
%
% DBR 12/00

global mrSESSION

if ~exist('compFlag'), compFlag = 0; end
if ~exist('rotFlag'), rotFlag = 0; end

% Do recon, extract complex time series:
[aTS, bTS] = PaulyRecon(scanParams, fName, slice, compFlag, rotFlag);

% Remove junk frames:
f0 = mrSESSION.junkFirstFrames+1;
nFrames = mrSESSION.nFrames;
fEnd = f0 + nFrames - 1;

% Crop:
x0 = mrSESSION.tseriesCrop(1, 1) + shifts(2);
xN = mrSESSION.tseriesCrop(2, 1) + shifts(2);
y0 = mrSESSION.tseriesCrop(1, 2) + shifts(1);
yN = mrSESSION.tseriesCrop(2, 2) + shifts(1);

% Crop in time/space and shuffle to standard t-series shape:
aTS = aTS(f0:fEnd, :, :);
aTS = aTS(:, y0:yN, x0:xN);
aTS = reshape(aTS, nFrames, (yN-y0+1)*(xN-x0+1));
if compFlag
  bTS = bTS(f0:fEnd, :, :);
  bTS = bTS(:, y0:yN, x0:xN);
  bTS = reshape(bTS, nFrames, (yN-y0+1)*(xN-x0+1));
end
