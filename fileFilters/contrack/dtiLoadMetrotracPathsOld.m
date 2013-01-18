function mtPaths = dtiLoadMetrotracPathsOld(filename,xform)
%
% mtPaths = dtiLoadMetrotracPathsOld(filename)
%
% Loads fiber pathways from a metrotrac .dat file. 
% 
%
% HISTORY:
% 2006.08.17 Written by Bob Dougherty and Anthony Sherbondy.
% 2006.11.21 RFD: I reorganized the output sturcture to allow for more
% efficient processing of large arrays of pathways.
% 2006.12.24 AJS: Enabled statistics to be loaded into the paths structure


fid_in = fopen(filename, 'rb');

% Reading Database header
offset = fread(fid_in,1,'uint');
mtPaths.scene_dim = fread(fid_in,3,'uint');
mtPaths.mm_scale = fread(fid_in,3,'double');
mtPaths.ACPC = fread(fid_in,3,'double');

%xformToAcpc = inv(affineBuild(mtPaths.ACPC, [0 0 0],1./mtPaths.mm_scale'));

% Pathways seem to already be in mm space.
% XXX Can't trust ACPC info in file all the time for some reason, first
% found error on Brian's computer with case ahPI060114
%xformToAcpc = affineBuild(-mtPaths.ACPC.*mtPaths.mm_scale, [0 0 0], [1 1 1]);
xformToAcpc = xform*diag([1./(mtPaths.mm_scale(:)') 1]);
% We also have to add a single-voxel offset (0/1 index difference?)
xformToAcpc = xformToAcpc*[eye(3),mtPaths.mm_scale(:);0 0 0 1];

numstats = fread(fid_in,1,'uint');

% XXX Read stat header
mtPaths.statHeader = loadStatisticsHeader(fid_in,numstats);

fseek(fid_in,offset,-1);

% Reading path info
npaths = fread(fid_in,1,'int');

for p = 1:npaths    
    % Creating new pathway object and adding to database

    % Read offset
    path_offset = fread(fid_in,1,'int');
    % Record current file position
    ppos = ftell(fid_in);
    if(ppos == -1)
        disp('Error reading pathway database.')
    end
    % Reading per path header
    numnodes = fread(fid_in,1,'int');

    mtPaths.pathwayInfo(p).algo_type = fread(fid_in,1,'int'); % algo type
    mtPaths.pathwayInfo(p).seed_point_index = fread(fid_in,1,'int'); % seedpointindex ???
    for as = 1:numstats
        mtPaths.pathwayInfo(p).pathStat(as) = fread(fid_in,1,'double');
    end
    
    % Seek past header
    fseek(fid_in,ppos+path_offset,-1);
    
    % Reading path positions
    mtPaths.pathways{p,1} = fread(fid_in,numnodes*3,'double');
    mtPaths.pathways{p,1} = reshape(mtPaths.pathways{p,1},3,numnodes);
    % Reading stats values per position
    for as = 1:numstats
        if(mtPaths.statHeader(as).is_computed_per_point)
            mtPaths.pathwayInfo(p).point_stat_array(as,:) = fread(fid_in,numnodes,'double');
        end
    end   
end
fclose(fid_in);
% Transform all fiber coords in one go (much faster!)
mtPaths.pathways = dtiXformFiberCoords(mtPaths.pathways, xformToAcpc);
return;


function this = loadStatisticsHeader(fid,numstats)
this = [];
for s = 1:numstats
    this(s).is_luminance_encoding = fread(fid,1,'char');
    this(s).is_computed_per_point = fread(fid,1,'char');
    this(s).is_viewable_stat = fread(fid,1,'char');
    vectemp = fread(fid,255,'char');
    this(s).agg_name = char(vectemp(1:max(1,min(find(~vectemp))-1))');
    vectemp = fread(fid,255,'char');
    this(s).local_name = char(vectemp(1:max(1,min(find(~vectemp))-1))');;
    this(s).uid = fread(fid,1,'uint');
    % Read garbage at end for word alignment
    garb_size = getStatisticsHeaderSizeWordAligned(this(s)) - getStatisticsHeaderSize(this(s));
    foo = fread(fid,garb_size,'char');
end
return;

function s = getStatisticsHeaderSizeWordAligned(this)
% Assume a word is 4 bytes
s = getStatisticsHeaderSize(this);
s = ceil(s/4)*4;
return;

function s = getStatisticsHeaderSize(this)
s = 1 + 1 + 1 + 255 + 255 + 4;
return;
