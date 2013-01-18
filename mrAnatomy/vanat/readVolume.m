function [vData, vSize ] = readVolume(fname)
%
%  [vData vSize] = readVolume(fname)
%
%AUTHOR:  Wandell
%DATE:    08.22.95
%PURPOSE:
%   Read in volume data written by mrUnfold.  The images are in
% the rows of vData, which is [vSize(3) vSize(1)*vSize(2)] = [nplanes row*col].
%
% ARGUMENTS:
% fname:  Input filename
%
% RETURNS:
% vData:  volume data is a matrix of size [nplanes row*col] where each
%         row is an image.  The data are organized this way because of
%         the way mrSeries returns a volume data after reading in the
%         Signa file.
% vSize:  [row col nplanes]
%
% HISTORY:
% 07.16.97 ABP	Cosmetic changes telling user about reading volumes.
% 08.06.98 SJC	Changed user messages from being printed at the Matlab
%		prompt to graphical message boxes
%
 

disp('**Code calling readVolume should be updated to readVolAnat**')
fprintf('\nReading volume file %s\n',fname);

endOfHeader = '*';

vFile = fopen(fname,'rb');
vSize(1) = fscanf(vFile,'rows %f\n');
vSize(2) = fscanf(vFile,'cols %f\n');
vSize(3) = fscanf(vFile,'planes %f\n');
fprintf ('\nFound a volume with %d rows, %d cols, %d planes\n',vSize(1),vSize(2),vSize(3));

% This is bad.  I read in the '*" and the \n, but I should really
% be checking, not assuming
[c cnt] = fread(vFile,2,'uint8');

msg = sprintf('Reading volume file: %s...',fname);
h = msgbox(msg,'Load Volume File');
pause(1)
nToRead=prod(vSize);
fprintf('\nAttempting to read %d bytes\n',nToRead);
[vData cnt] = fread(vFile,nToRead,'uint8');

fclose(vFile);
fprintf ('\nRead %d bytes of data\n',cnt);

if exist('h'), close(h); end

% Now, we undo the C versus Fortran coding.  At this point,
% because we read it in in C ordering, row and columns are
% reversed in the data.  That is why vSize(2) and vSize(1) are in
% the positions they are in.  After the final transpose, however, 
% they have the right meaning.

vData = reshape(vData,vSize(1)*vSize(2),vSize(3));
vData = vData';

for i=1:vSize(3)
 tmp = vData(i,:);
 tmp = reshape(tmp,vSize(2),vSize(1));
 tmp = tmp';
 tmp = tmp(:);
% mrShowImage(tmp,[vSize(1) vSize(2)],'s',gray(128));
 vData(i,:) = tmp';
end

% mrShowImage(vData(i,:),iSize,'s',gray(128))

return
