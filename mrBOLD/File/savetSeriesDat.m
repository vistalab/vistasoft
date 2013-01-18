function savetSeriesDat(pathStr,tSeries,nRows,nCols)
%function savetSeriesDat(pathStr,tSeries,[nRows,nCols]) 
%
%98.12.23 - Written by Bill and Bob.  Save the tSeries in the new
%uint16 format, including writing out header information.
%nRows and nCols are optional arguments.  If not supplied, the
%header will contain: nRows=1, nCols=real#rows * real#cols.
%
% djh, 2/16/2001
%    pass in full path string to avoid changing directories.

if nargin==2
  nRows = 1;
  nCols = size(tSeries,2);
elseif nargin~=4
  error(['Must pass in either both nRows and nCols or neither.']);
end

nFrames = size(tSeries,1);

fid = fopen(pathStr,'w','b');
fwrite(fid, nFrames, 'uint16');
fwrite(fid, nRows, 'uint16');
fwrite(fid, nCols, 'uint16');
fwrite(fid, tSeries ,'uint16');
fclose(fid);







