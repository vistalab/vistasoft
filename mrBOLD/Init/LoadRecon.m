function [tsA, tsB] = LoadRecon(scanParams, fName, slice, rotFlag, endianFlag)
% Load the reconstructed time series produced by Gary Glover's
% spiral reconstruction code.
%
%  [tsA, tsB] = LoadRecon(scanParams, fName, slice, rotFlag, endianFlag]);
%
% DBR 8/01
% ras 03/05: added Endian Flag, removed comp flag since
%   the complex code doesn't even seem to have worked for
%    more than 4 years!

%if ~exist('compFlag'), compFlag = 0; end
if ~exist('rotFlag', 'var'), rotFlag = 0; end

if ieNotDefined('endianFlag') || isequal(endianFlag,0)
    endianFlag = 'ieee-le'; 
end

% The following 3 lines don't seem to do anything.
%   fNames          = {scanParams.PfileName};
%   [p, name, ext]  = fileparts(fName);
%   scan            = strmatch(name, fNames);

nFrames = scanParams.totalFrames;
fSize = scanParams.fullSize;
offset = prod(fSize) * 2 * (slice - 1) * nFrames;

% Read in magnitude component:
mN = fopen(fName, 'r', endianFlag);
tsA = zeros([nFrames, fSize]);
fseek(mN, offset, 0); % Skip to desired slice
for f=1:nFrames
    img = fread(mN, fSize, 'int16', endianFlag)';
    if rotFlag, img = rot90(img, -1); end
    tsA(f, :, :) = img;
end
fclose(mN);

% delete(fnMag);
tsB = [];

return
