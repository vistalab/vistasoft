function mtPaths = dtiLoadMetrotracPaths(filename,xform)
%
% mtPaths = dtiLoadMetrotracPaths(filename)
%
% Loads fiber pathways from a metrotrac .dat file. 
% 
%
% HISTORY:
% 2006.08.17 Written by Bob Dougherty and Anthony Sherbondy.
% 2006.11.21 RFD: I reorganized the output sturcture to allow for more
% efficient processing of large arrays of pathways.
% 2006.12.24 AJS: Enabled statistics to be loaded into the paths structure
% 2009.02.02ish AJS: Around this date, Tony appears to have fixed various
% issues related to parsing the pdb file.  

%% Open file
fid_in = fopen(filename, 'r');

%% Reading Database header
offset = fread(fid_in,1,'uint');

% Read in xform row-order
mtPaths.xform = fread(fid_in,16,'double');
mtPaths.xform = reshape(mtPaths.xform,4,4)';

E = eye(4);
% XXX Just assume ACPC paths because of old DTIQuery method
bOnlyMatlabXForm=0;  % XXX this was 1 before 1/17
if sum(abs(mtPaths.xform(:)-E(:))) < 0.001
    bOnlyMatlabXForm=1;
end

% Read stat header
numstats = fread(fid_in,1,'uint');
mtPaths.statHeader = loadStatisticsHeader(fid_in,numstats);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XXX REAL BAD HACK HERE DON'T KNOW HOW TO FIX THE WORD ALIGNMENT ISSUE YET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read algorithms header
%numalgs = fread(fid_in,1,'uint');
%mtPaths.algHeader = loadAlgorithmsHeader(fid_in,numalgs);
fseek(fid_in,offset-4,'bof');

version = fread(fid_in,1,'int');
disp(['PDB version ' num2str(version)]);
if version<2
    disp('PDB must be version 2 or greater!');
    mtPaths = [];
    fclose(fid_in);
    return;
end

% Skip to end of header
fseek(fid_in,offset,-1);


% %% Calculate ACPC xform
% % XXX for now we don't trust the xform stored in the file
% mtPaths.mm_scale = abs([mtPaths.xform(1,1) mtPaths.xform(2,2) mtPaths.xform(3,3)]);
% xformToAcpc = xform*diag([1./(mtPaths.mm_scale(:)') 1]);
% % We also have to add a single-voxel offset (0/1 index difference?)
% xformToAcpc = xformToAcpc*[eye(3),mtPaths.mm_scale(:);0 0 0 1];


%% Reading each pathway
npaths = fread(fid_in,1,'int');   
for p = 1:npaths    
    % Creating new pathway object and adding to database

    % Read offset header size
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
%     if( bOnlyMatlabXForm )
%         mtPaths.pathways{p,1} = mtPaths.pathways{p,1}+2;
%     end
    % Reading stats values per position
    for as = 1:numstats
        if(mtPaths.statHeader(as).is_computed_per_point)
            mtPaths.pathwayInfo(p).point_stat_array(as,:) = fread(fid_in,numnodes,'double');
        end
    end
    if mod(p,10000)==0
        disp(['Loaded ' num2str(p) ' of ' num2str(npaths)]);
    end
end
fclose(fid_in);
% Transform all fiber coords in one go (much faster!)
% I don't know why this offset is still necessary, isn't ACPC space all
% ACPC space??
if( ~bOnlyMatlabXForm )
    %xformToMatlab = [1 0 0 2; 0 1 0 2; 0 0 1 2; 0 0 0 1];
    xformToMatlab = eye(4);
    xformToAcpc = xformToMatlab*mtPaths.xform;
    mtPaths.pathways = dtiXformFiberCoords(mtPaths.pathways, xformToAcpc);
end

return;

function this = loadStatisticsHeader(fid,numstats)
this = [];
for s = 1:numstats
    this(s).is_luminance_encoding = fread(fid,1,'int');
    this(s).is_computed_per_point = fread(fid,1,'int');
    this(s).is_viewable_stat = fread(fid,1,'int');
    vectemp = fread(fid,255,'uchar');
    this(s).agg_name = char(vectemp(1:max(1,min(find(~vectemp))-1))');
    vectemp = fread(fid,255,'uchar');
    this(s).local_name = char(vectemp(1:max(1,min(find(~vectemp))-1))');
    foo = fread(fid,2,'uchar'); % Must have integer reads be word aligned
    this(s).uid = fread(fid,1,'int');
    % Read garbage at end for word alignment
    %garb_size = getStatisticsHeaderSizeWordAligned(this(s)) - getStatisticsHeaderSize(this(s));
    %foo = fread(fid,garb_size,'char');
end
return;

function this = loadAlgorithmsHeader(fid,numalgs)
this = [];
for s = 1:numalgs
    vectemp = fread(fid,255,'uchar');
    this(s).name = char(vectemp(1:max(1,min(find(~vectemp))-1))');
    vectemp = fread(fid,255,'uchar');
    this(s).comments = char(vectemp(1:max(1,min(find(~vectemp))-1))');
    foo = fread(fid,2,'uchar'); % Must have integer reads be word aligned
    this(s).uid = fread(fid,1,'uint');
    % Read garbage at end for word alignment
    %garb_size = getAlgorithmsHeaderSizeWordAligned(this(s)) - getAlgorithmsHeaderSize(this(s));
    %foo = fread(fid,garb_size,'char');
end
return;

% function s = getStatisticsHeaderSizeWordAligned(this)
% % Assume a word is 8 bytes
% s = getStatisticsHeaderSize(this);
% %s = ceil(s/4)*4;
% s = ceil(s/8)*8;
% return;
% 
% function s = getStatisticsHeaderSize(this)
% s = 4 + 4 + 4 + 255 + 255 + 4;
% return;
% 
% function s = getAlgorithmsHeaderSizeWordAligned(this)
% % Assume a word is 8 bytes
% s = getAlgorithmsHeaderSize(this);
% %s = ceil(s/4)*4;
% s = ceil(s/8)*8;
% return;
% 
% function s = getAlgorithmsHeaderSize(this)
% s = 255 + 255 + 4;
% return;
