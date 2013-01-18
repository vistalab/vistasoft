function [tSeries,nRows,nCols,nFrames] = loadtSeriesDat(pathStr)
% Load a tSeries.dat file
%
%   [tSeries,nRows,nCols,nFrames] = loadtSeriesDat(pathStr)
%
% ***** Obsolete:  see loadtSeries ******
%
% This routine reads in a tSeries with the ".dat" extension, taking into
% account header information specifying the number of time frames, the
% number of rows in each image, and the number of columns in each image. 
%
% 98.12.23 - Created by Bill and Bob.  
% 2000.02.25 Modified to carry on if nVals~=nFrames*nRows*nCols. 
% Guesses that nCols=nVals/nFrames; ARW

if ~exist(pathStr,'file'), error('Cannot find file %s\n',pathStr); end
    
% Modern tSeries are stored as 2 bytes, unsigned.  
% We use big-endian format on all machines.

fid = fopen(pathStr,'r','b');
nFrames = fread(fid,1,'uint16');
nRows = fread(fid,1,'uint16');
nCols = fread(fid,1,'uint16');
[tSeries,nVals] = fread(fid,[nFrames,inf],'uint16');
fclose(fid);

if (nVals ~= nFrames*nRows*nCols)
  disp ('error:loadtSeriesDat: header information does not match file size.');
  nCols=nVals/nFrames;
  nRows=1;
end

return;
