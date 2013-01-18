function mtPaths = dtiLoadMetrotracPathsFast(filename)
%
% mtPaths = dtiLoadMetrotracPathsFast(filename)
%
% Loads fiber pathways from a metrotrac .dat file. 
% 
%
% HISTORY:
% 2006.08.17 Written by Bob Dougherty and Anthony Sherbondy.
% 2006.11.21 RFD: I reorganized the output sturcture to allow for more
% efficient processing of large arrays of pathways.
% 2006.12.24 AJS: Enabled statistics to be loaded into the paths structure

%% Open file
fid_in = fopen(filename, 'rb');

%% Reading Database header
offset = fread(fid_in,1,'uint');
% Read in xform row-order
mtPaths.xform = fread(fid_in,16,'double');
mtPaths.xform = reshape(mtPaths.xform,4,4)';
E = eye(4);
% XXX Just assume ACPC paths because of old DTIQuery method
bOnlyMatlabXForm=0;
if sum(abs(mtPaths.xform(:)-E(:))) < 0.001
    bOnlyMatlabXForm=1;
end
% Read stat header
numstats = fread(fid_in,1,'uint');
mtPaths.statHeader = loadStatisticsHeader(fid_in,numstats);
% Read algorithms header
numalgs = fread(fid_in,1,'uint');
mtPaths.algHeader = loadAlgorithmsHeader(fid_in,numalgs);
% Skip to end of header
fseek(fid_in,offset,-1);

%% Now load pathway endpoints and per path stats
npaths = fread(fid_in,1,'int');
% Just loading endpoints so make a simple endpoint matrix
mtPaths.pathways = zeros(3,2,npaths);
mtPaths.pathstats = zeros(numstats,npaths);
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
    fread(fid_in,1,'int'); % algo type
    fread(fid_in,1,'int'); % seedpointindex ???
    for as = 1:numstats
        mtPaths.pathstats(as,p) = fread(fid_in,1,'double');
    end
    
    % Seek past header
    fseek(fid_in,ppos+path_offset,-1);            
    
    % Reading path positions
    pathway = fread(fid_in,numnodes*3,'double');
    mtPaths.pathways(:,1:numnodes,p) = reshape(pathway,3,numnodes);

    % Reading stats values per position
    for as = 1:numstats
        if(mtPaths.statHeader(as).is_computed_per_point)
            fread(fid_in,numnodes,'double');
        end
    end
    if mod(p,10000)==0
        disp(['Loaded ' num2str(p) ' of ' num2str(npaths)]);
    end
end
fclose(fid_in);

% if( bOnlyMatlabXForm )
%     mtPaths.pathways = mtPaths.pathways+2;
% end

% Transform all fiber coords in one go (much faster!)
% I don't know why this offset is still necessary, isn't ACPC space all
% ACPC space??
if( ~bOnlyMatlabXForm )
    %xformToMatlab = [1 0 0 2; 0 1 0 2; 0 0 1 2; 0 0 0 1];
    xformToMatlab = eye(4);
    xformToAcpc = xformToMatlab*mtPaths.xform;
    %xformToAcpc = xformToMatlab*inv(eye(4));
    mtPaths.pathways = reshape(mrAnatXformCoords(xformToAcpc, reshape(mtPaths.pathways,3,2*npaths))',[3 2 npaths]);
end

return;

function this = loadStatisticsHeader(fid,numstats)
this = [];
for s = 1:numstats
    this(s).is_luminance_encoding = fread(fid,1,'int');
    this(s).is_computed_per_point = fread(fid,1,'int');
    this(s).is_viewable_stat = fread(fid,1,'int');
    vectemp = fread(fid,255,'char');
    this(s).agg_name = char(vectemp(1:max(1,min(find(~vectemp))-1))');
    vectemp = fread(fid,255,'char');
    this(s).local_name = char(vectemp(1:max(1,min(find(~vectemp))-1))');;
    this(s).uid = fread(fid,1,'int');
    % Read garbage at end for word alignment
    garb_size = getStatisticsHeaderSizeWordAligned(this(s)) - getStatisticsHeaderSize(this(s));
    foo = fread(fid,garb_size,'char');
end
return;

function this = loadAlgorithmsHeader(fid,numalgs)
this = [];
for s = 1:numalgs
    vectemp = fread(fid,255,'char');
    this(s).name = char(vectemp(1:max(1,min(find(~vectemp))-1))');
    vectemp = fread(fid,255,'char');
    this(s).comments = char(vectemp(1:max(1,min(find(~vectemp))-1))');
    this(s).uid = fread(fid,1,'uint');
    % Read garbage at end for word alignment
    garb_size = getAlgorithmsHeaderSizeWordAligned(this(s)) - getAlgorithmsHeaderSize(this(s));
    foo = fread(fid,garb_size,'char');
end
return;

function s = getStatisticsHeaderSizeWordAligned(this)
% Assume a word is 4 bytes
s = getStatisticsHeaderSize(this);
s = ceil(s/4)*4;
return;

function s = getStatisticsHeaderSize(this)
s = 4 + 4 + 4 + 255 + 255 + 4;
return;

function s = getAlgorithmsHeaderSizeWordAligned(this)
% Assume a word is 4 bytes
s = getAlgorithmsHeaderSize(this);
s = ceil(s/4)*4;
return;

function s = getAlgorithmsHeaderSize(this)
s = 255 + 255 + 4;
return;