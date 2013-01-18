function saveDatabase(this,filename)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% writechain(filename,holdingchains,sceneDim,mmPerVox,ACPC)
%%
%% filename - file we will append this chain to
%% holdingchains - A struct which contains the following:
%%      xpos, ypos, zpos - vectors defining position of chain in 3D
%%      weight - weight of chain
%%
%%
%% Author: Anthony Sherbondy
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numstats = length( this.pathway_statistic_headers );

% Redo offset
offset = 5*4 + 6*8 + numstats * getStatisticsHeaderSizeWordAligned(this); % 5 uint,6 doubles
%5* sizeof (int) + 6 * sizeof(double) + pathways->getNumPathStatistics()*sizeof (DTIPathwayStatisticHeader);
% bool == char, but not guaranteed on all platforms

fid = fopen(filename, 'wb');

% Writing header
fwrite(fid,offset,'uint');

fwrite(fid,this.scene_dim,'uint');
fwrite(fid,this.mm_scale,'double');
fwrite(fid,this.ACPC,'double');
fwrite(fid,numstats,'uint');

% Write Stat Header
saveStatisticsHeader(this,fid);

%Writing path info
numpaths = length(this.pathways);
fwrite(fid,numpaths,'uint');

for p = 1:numpaths
    path_offset = 3 * 4  + numstats*8; % 3 int, numstats double
    fwrite(fid,path_offset,'int');
    
    nn = length( this.pathways(p).xpos );
    
    fwrite(fid,nn,'int');
    fwrite(fid,this.pathways(p).algo_type,'int'); % algo type
    fwrite(fid,this.pathways(p).seed_point_index,'int'); % seedpointindex ???
    
    % Stats
    for as = 1:numstats
        fwrite(fid,this.pathways(p).path_stat_vector(as),'double');
    end    
    
    % Writing path nodes
    %fwrite(fid,[holdingchains(p).xpos*mmPerVox(1); holdingchains(p).ypos*mmPerVox(2); holdingchains(p).zpos*mmPerVox(3)],'double');
    pos = asMatrixStruct(this.pathways(p));
    % Change from 0 based to 1 based positions
    pos = pos - repmat(this.mm_scale(:),1,size(pos,2));
    fwrite(fid,pos,'double');
    
    % Writing stats values per position
    for as = 1:numstats
        if( this.pathway_statistic_headers(as).is_computed_per_point )
            fwrite(fid,this.pathways(p).point_stat_array(as,:),'double');
        end
    end    
end

disp('Saved Database.');
fclose(fid);

function pos = asMatrixStruct(this)
pos = [this.xpos; this.ypos; this.zpos];
return