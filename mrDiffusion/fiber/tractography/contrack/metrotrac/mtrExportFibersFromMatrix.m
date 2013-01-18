function mtrExportFibersFromMatrix(pathwayMatrix, pathwayLengthVec, statsVec, statsNames, fileName, xformToMm)
%Exports pathway matrix (3,max_path_length,num_paths) to .pdb format
%
% This routine does not appear to be used much.
%
%   mtrExportFibersFromMatrix(pathwayMatrix, pathwayLengthVec, fileName, xformToAcPc, xform)
% 
% See also: mtrNotes
%
% Examples
%
% 
% HISTORY:
% 2008.01.13 AJS: wrote it.
%
%
% Stanford VISTA Team

if(~exist('xformToMm','var')),  xformToMm = eye(4); end

% Create blank database for finding some of the sizes to write out
pdb = mtrPathwayDatabase();

% PDB structure will have stat header info, but fg will retain the actual
% statistics per path to record
mmPerStep = sqrt(sum((pathwayMatrix(:,1,1)-pathwayMatrix(:,2,1)).^2));
[pdb,fg] = makeStatsFromStatsVec(pdb,pathwayLengthVec,mmPerStep, statsVec, statsNames);
numstats = length( pdb.pathway_statistic_headers );
numalgs = 0;

% Redo offset
offset = 4*4 + 16*8 + numstats * getStatisticsHeaderSizeWordAligned(pdb) + numalgs * getAlgorithmsHeaderSizeWordAligned(pdb); % 4 uint, 16 doubles

fid = fopen(fileName, 'wb');

% Writing header
fwrite(fid,offset,'uint');
xformToMm = xformToMm';
fwrite(fid,xformToMm(:),'double');
fwrite(fid,numstats,'uint');

% Write stat header
saveStatisticsHeader(pdb,fid);

fwrite(fid,numalgs,'uint');
% Write algorithm header
%saveAlgorithmHeader(pdb,fid);

% Write version info
version = 1;
fwrite(fid,version,'uint');

%Writing path info
numpaths = length(pathwayLengthVec);
fwrite(fid,numpaths,'uint');
fileOffsets = zeros(1,numpaths);
for ff = 1:numpaths
    % Record current file position to write later
    fileOffsets(ff) = ftell(fid);
    
    path_offset = 3 * 4  + numstats*8; % 4 int, numstats double
    fwrite(fid,path_offset,'int');    
    nn = pathwayLengthVec(ff);    
    fwrite(fid,nn,'int');
    fwrite(fid,0,'int'); % algo type HACK
    fwrite(fid,1,'int'); % seedpointindex HACK ???
    
    % Write stats per path
    for as = 1:numstats
        fwrite(fid,fg.params{as}.stat(ff),'double');
    end 
    
    % Writing path nodes
    %pos = fg.fibers{ff}.coords;
    pos = pathwayMatrix(:,1:pathwayLengthVec(ff),ff);
    %pos = mrAnatXformCoords(xformFromAcpc, pos')';
    % Change from 1 based to 0 based positions in mm space
    %pos = pos - repmat([2,2,2]',1,size(pos,2));
    fwrite(fid,pos,'double');
    
    % Writing stats values per position
    for as = 1:numstats
        % Just write garbage as fiber groups can't handle per point stats
        if( pdb.pathway_statistic_headers(as).is_computed_per_point )
            error('Cannot export fiber group with per point statistics!');
            %fwrite(fid,this.pathways(p).point_stat_array(as,:),'double');
        end
    end   
end

% Database Footer
fwrite(fid,fileOffsets,'uint32');

fclose(fid);
return;

function [pdb, fg] = makeStatsFromStatsVec(pdb, lengthVec, mmPerStep, statsVec, statsNames)

fg = dtiNewFiberGroup();
fg.params = {};
fg.params{1}.name = 'Length';
for ff=1:length(lengthVec)
    fg.params{1}.stat(ff) = mmPerStep*(lengthVec(ff)-1);
end
s=length(pdb.pathway_statistic_headers)+1;
pdb = addStatisticHeader(pdb,'Length','NA', 1, 0, 1, 8877+s);

for ii=2:min(length(statsNames)+1,3)
    % Add up to two stats from the provided vectors
    fg.params{ii}.name = statsNames{ii-1};
    for ff=1:size(statsVec,2)
        fg.params{ii}.stat(ff) = statsVec(ii-1,ff);
    end
    s=length(pdb.pathway_statistic_headers)+1;
    pdb = addStatisticHeader(pdb,statsNames{ii-1},'NA', 1, 0, 1, 8877+s);
end

for ii=(length(statsNames)+2):3
    % Add blank stats to fill up to 3 required by pdb format.
    pdb = addBlankStat(pdb,'Blank');
    fg.params{ii}.name = 'Blank';
    fg.params{ii}.stat = zeros(1,length(lengthVec));
end

return;

function pdb = addBlankStat(pdb,agg_name)
s=length(pdb.pathway_statistic_headers)+1;
pdb = addStatisticHeader(pdb,agg_name,'NA', 1, 0, 1, 8877+s);
return;