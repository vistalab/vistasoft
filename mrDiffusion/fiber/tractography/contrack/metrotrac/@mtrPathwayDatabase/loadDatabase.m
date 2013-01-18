function [this] = loadDatabase(this,filename,pathIDs)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% [objPathwayDabase] = loadPathwayDatabase(objPathwayDabase,filename)
%%
%% filename - file we will read the chains from
%% pathsIDs - Only load these paths.
%%
%% Author: Anthony Sherbondy
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Constant needed
bytes_double = 8;


% Empty current pathways
this.pathways = mtrPathwayStruct();

fid_in = fopen(filename, 'rb');

% Reading Database header
offset = fread(fid_in,1,'uint');
this.scene_dim = fread(fid_in,3,'uint');
this.mm_scale = fread(fid_in,3,'double');
this.ACPC = fread(fid_in,3,'double');

numstats = fread(fid_in,1,'uint');

% XXX Read stat header
this = loadStatisticsHeader(this,fid_in,numstats);

fseek(fid_in,offset,-1);

% Reading path info
npaths = fread(fid_in,1,'int');
if(ieNotDefined('pathIDs'))
    pathIDs = [1:npaths];
end
if(max(pathIDs)>npaths)
    error('Desired paths to load do not exist in file.');
end

for p = 1:npaths    
    
    % See if this is one of the pathways that we should be loading
    bLoadPath = length(find(pathIDs==p));    
    
    % Creating new pathway object and adding to database
    %this.pathways(p) = DTIPathway();
    % Read offset
    path_offset = fread(fid_in,1,'int');
    % Record current file position
    ppos = ftell(fid_in);
    if(ppos == -1)
        disp('Error reading pathway database.')
    end
    % Reading per path header
    numnodes = fread(fid_in,1,'int');

    this.pathways(p).algo_type = fread(fid_in,1,'int'); % algo type
    this.pathways(p).seed_point_index = fread(fid_in,1,'int'); % seedpointindex ???
    
    % Read aggregate path statistics
    numstats = length(this.pathway_statistic_headers);
    this.pathways(p).path_stat_vector = zeros(numstats,1);
    
    for as = 1:numstats
        this.pathways(p).path_stat_vector(as) = fread(fid_in,1,'double');
    end

    % Seek past header
    fseek(fid_in,ppos+path_offset,-1);
    
    % Reading path positions
    if(bLoadPath)
        pos = fread(fid_in,numnodes*3,'double');
        pos = reshape(pos,3,numnodes);
        % Change from 0 based to 1 based positions
        pos = pos + repmat(this.mm_scale(:),1,numnodes);
        this.pathways(p) = setPosMatrixStruct(this.pathways(p),pos);
    else
        % Bogus zero positions
        this.pathways(p) = setPosMatrixStruct(this.pathways(p),zeros(3,numnodes));
        % Seek past these positions
        fseek(fid_in,numnodes*3*bytes_double,'cof');
    end
    
    % Reading stats values per position
    for as = 1:numstats
        if(this.pathway_statistic_headers(as).is_computed_per_point)
            if(bLoadPath)
                this.pathways(p).point_stat_array(as,:) = fread(fid_in,numnodes,'double');
            else
                % Bogus zero positions
                this.pathways(p).point_stat_array(as,:) = zeros(1,numnodes);
                % Seek past these positions
                fseek(fid_in,numnodes*bytes_double,'cof');
            end
        end
    end   
end

disp('Loaded pathway database.');
fclose(fid_in);

function this = setPosMatrixStruct(this,pos)
this.xpos = pos(1,:);
this.ypos = pos(2,:);
this.zpos = pos(3,:);
return;
