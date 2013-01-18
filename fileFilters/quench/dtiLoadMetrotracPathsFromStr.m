function mtPaths = dtiLoadMetrotracPathsFromStr(str,xform)
% Load a fiber group from a pdb file 
%
%   metroTracFormat = dtiLoadMetrotracPathsFromStr(str,xform)
%
% The pdb file is read into a structure that is returned.  This routine is
% called by mtrImportFibers which then also repackages the metrocTracFormat
% into the fg format used by mrDiffusion.
%
% Example:
%
% See also:  mtrImportFibers
%
% (c) Stanford VISTA 2009


%% Initialize count
i=1;
int32size   = size(typecast(int32(0),'uint8'),2);
doublesize = size(typecast(double(0.0),'uint8'),2);

%% Reading Database header
offset = typecast( uint8(str(i:i+int32size-1)),'uint32'); 
i = i + int32size;

% Read in xform row-order
mtPaths.xform = typecast( uint8(str(i:i+doublesize*16-1)),'double'); 
i = i + doublesize*16;
mtPaths.xform = reshape(mtPaths.xform,4,4)';

E = eye(4);

% XXX Just assume ACPC paths because of old DTIQuery method
bOnlyMatlabXForm=0;  % XXX this was 1 before 1/17
if sum(abs(mtPaths.xform(:) - E(:))) < 0.001
    bOnlyMatlabXForm=1;
    disp('dtiLoadMetrotracPathsFromStr: Calling a Matlab X Form');
end

% Read stat header
numstats = typecast( uint8(str(i:i+int32size-1)),'uint32'); i = i + int32size;
[mtPaths.statHeader i] = loadStatisticsHeader(str,numstats,i,int32size);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XXX REAL BAD HACK HERE DON'T KNOW HOW TO FIX THE WORD ALIGNMENT ISSUE YET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read algorithms header
%numalgs = fread(fid_in,1,'uint');
%mtPaths.algHeader = loadAlgorithmsHeader(fid_in,numalgs);
i = offset-3;

version = typecast( uint8(str(i:i+int32size-1)),'int32'); i = i + int32size;
disp(['PDB version ' num2str(version)]);
if version<2
    disp('PDB must be version 2 or greater!');
    mtPaths = [];
    return;
end

% We are done here if this is version 3
if version == 3
    mtPaths = dtiLoadMetrotracPathsFromStrVer3(str,i,numstats,mtPaths, xform);
    return;
end

% We are in version 2 land here, I guess.

% Skip to end of header
i=offset+1;


%% Reading each pathway
npaths = typecast( uint8(str(i:i+int32size-1)),'int32'); i = i + int32size;
for p = 1:npaths    
    % Creating new pathway object and adding to database

    % Read offset header size
    path_offset = typecast( uint8(str(i:i+int32size-1)),'uint32'); i = i + int32size;
    % Record current file position
    ppos = i;
    if(ppos == -1)
        disp('Error reading pathway database.')
    end
    
    % Reading per path header
    numnodes = typecast( uint8(str(i:i+int32size-1)),'uint32'); i = i + int32size;
    mtPaths.pathwayInfo(p).algo_type = typecast( uint8(str(i:i+int32size-1)),'int32'); 
    i = i + int32size; % algo type
    mtPaths.pathwayInfo(p).seed_point_index = typecast( uint8(str(i:i+int32size-1)),'int32'); 
    i = i + int32size; % seedpointindex ???
    for as = 1:numstats
        mtPaths.pathwayInfo(p).pathStat(as) = typecast( uint8(str(i:i+doublesize-1)),'double'); 
        i = i + doublesize;
    end
    
    % Seek past header
    i=ppos+path_offset;
    
    % Reading path positions
    mtPaths.pathways{p,1} = typecast( uint8(str(i:i+doublesize*numnodes*3-1)),'double'); 
    i = i + doublesize*numnodes*3;
    mtPaths.pathways{p,1} = reshape(mtPaths.pathways{p,1},3,numnodes);
%     if( bOnlyMatlabXForm )
%         mtPaths.pathways{p,1} = mtPaths.pathways{p,1}+2;
%     end
    % Reading stats values per position
    for as = 1:numstats
        if(mtPaths.statHeader(as).is_computed_per_point)
            mtPaths.pathwayInfo(p).point_stat_array(as,:) = typecast( uint8(str(i:i+doublesize*numnodes-1)),'double'); 
            i = i + doublesize*numnodes;
        end
    end
    if mod(p,10000)==0
        disp(['Loaded ' num2str(p) ' of ' num2str(npaths)]);
    end
end

% Transform all fiber coords in one go (much faster!)
% I don't know why this offset is still necessary, isn't ACPC space all
% ACPC space??
if( ~bOnlyMatlabXForm )
    %xformToMatlab = [1 0 0 2; 0 1 0 2; 0 0 1 2; 0 0 0 1];
    xformToMatlab = eye(4);
    %%%Use this or just xform?
    %xformToAcpc = xformToMatlab*xform;
    %xformToAcpc = xformToMatlab*mtPaths.xform+[0 0 0 -2; 0 0 0 -2; 0 0 0 -2; 0 0 0 1];
    xformToAcpc = xformToMatlab*mtPaths.xform;
    if isfield(mtPaths,'pathways')
        mtPaths.pathways = dtiXformFiberCoords(mtPaths.pathways, xformToAcpc);
    else
        mtPaths.pathways = [];
        mtPaths.pathwayInfo = [];
    end
end

return;


%% LoadStatisticsHeader
function [this iout]= loadStatisticsHeader(str,numstats,i,int32size)
this = [];
for s = 1:numstats
    this(s).is_luminance_encoding = typecast( uint8(str(i:i+int32size-1)),'int32'); i = i + int32size;
    this(s).is_computed_per_point = typecast( uint8(str(i:i+int32size-1)),'int32'); i = i + int32size;
    this(s).is_viewable_stat = typecast( uint8(str(i:i+int32size-1)),'int32'); i = i + int32size;
    vectemp = str(i:i+255); i = i + 255;
    this(s).agg_name = char(vectemp(1:max(1,min(find(~vectemp))-1))');
    vectemp = str(i:i+255); i = i + 255;
    this(s).local_name = char(vectemp(1:max(1,min(find(~vectemp))-1))');
    foo = str(i:i+2); i = i + 2; % Must have integer reads be word aligned
    this(s).uid = typecast( uint8(str(i:i+int32size-1)),'int32'); i = i + int32size;
    % Read garbage at end for word alignment
    %garb_size = getStatisticsHeaderSizeWordAligned(this(s)) - getStatisticsHeaderSize(this(s));
    %foo = fread(fid,garb_size,'char');
end
iout=i;
return;


%% Load Algorithms Header
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

