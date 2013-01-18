function dtiAppendFileOffsetsToPDB (fileOffsets, filename)

% function dtiAppendFileOffsetsToPDB (fileOffsets, filename)
%
% Appends file offsets for each pathway to the end of the pathways
% database. (Putting it at the end of the file means that we can write it out after all the
% pathways have been computed.)
%
% Author: DA

fid = fopen (filename, 'ab');
% should be at the end
fseek(fid,0,'eof');
fwrite (fid, fileOffsets, 'uint64');

