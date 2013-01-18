function dtiWritePDBHeader (xformToAcPc, filename)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% dtiWritePDBHeader(xformToAcPc, filename)
%
% filename - name of paths file to create.
%
% Author: DA
%
% 2008.02.15 RFD: added version field.
% 2008.02.15 AJS: corrected file for version 1 format.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numstats = 0;
numalgos = 1;
algoHeader = struct ('name', 'STT', ...
                    'comments', '', ...
                    'unique_id', 0);
version = 2;
if(numel(xformToAcPc)~=16)
    error('xform must be a 4x4!');
end

% Redo offset
offset = 4*4 + 16*8 + numalgos * dtiGetAlgoHeaderSizeWordAligned(); % 4 uint,16 doubles
%5* sizeof (int) + 6 * sizeof(double) + pathways->getNumPathStatistics()*sizeof (DTIPathwayStatisticHeader);
% bool == char, but not guaranteed on all platforms

fid = fopen(filename, 'wb');

% Writing header offset
fwrite(fid,offset,'uint');

% Write transform to get pathway into ACPC space
fwrite(fid,xformToAcPc,'double');

% Write Stat headers
fwrite(fid,numstats,'uint');
% saveStatisticsHeader(this,fid);

% Write Algo headers
fwrite (fid,numalgos, 'uint');      
dtiWriteAlgoHeader(algoHeader, fid);

% Write version
fwrite(fid,version,'uint');

disp('Saved database header.');
fclose(fid);
