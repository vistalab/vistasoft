function fileOffsets = dtiAppendPathwaysToPDB(fg, filename)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% dtiAppendDatabasePathways(toAppend, filename)
%
% toAppend: the pathway database we want to append to this file
% fileOffsets: an array of file offsets for each pathway.
% 
% Author: DA
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numstats = 0; % xxx
algoType = 0; % xxx

fid = fopen (filename, 'rb');
% figure out where num paths is, read it in
offset = fread (fid, 1, 'uint');
%fprintf ('Seeking to %d\n', offset);
fseek (fid, offset, -1);
[oldNumPaths, count] = fread (fid, 1, 'uint');
fclose (fid);
if count == 0
    %fprintf ('First time!');
    oldNumPaths = 0;
end
newNumPaths = oldNumPaths + length(fg.fibers);
fid = fopen (filename, 'r+b');
fseek (fid, offset, -1);
fwrite (fid, newNumPaths, 'uint');
fclose(fid);
fid = fopen (filename, 'ab');
fseek (fid, 0, 1);
fileOffsets = zeros(length(fg.fibers),1);

for p = 1:length(fg.fibers)
    fileOffsets(p) = ftell(fid);
    path_offset = 3 * 4  + numstats*8; % 3 int, numstats double
    fwrite(fid,path_offset,'int');
    
    nn = size(fg.fibers{p}, 2);
    
    fwrite(fid,nn,'int');
    fwrite(fid,algoType,'int'); % algo type
    fwrite(fid,0,'int'); % seedpointindex ???
    
    fwrite(fid,fg.fibers{p}(:), 'double');
    % Stats
    %for as = 1:numstats
     %   fwrite(fid,toAppend.pathways(p).path_stat_vector(as),'double');
    %end    
    
    % Writing path nodes
    %fwrite(fid,[holdingchains(p).xpos*mmPerVox(1); holdingchains(p).ypos*mmPerVox(2); holdingchains(p).zpos*mmPerVox(3)],'double');
    %pos = asMatrixStruct(toAppend.pathways(p));
    % Change from 0 based to 1 based positions
    %pos = pos - repmat(toAppend.mm_scale(:),1,size(pos,2));
    %fwrite(fid,pos,'double');
    
    % Writing stats values per position
    %for as = 1:numstats
    %    if( toAppend.pathway_statistic_headers(as).is_computed_per_point )
    %        fwrite(fid,toAppend.pathways(p).point_stat_array(as,:),'double');
    %    end
    %end    
end

%disp('Appended pathways to database.');
fclose(fid);