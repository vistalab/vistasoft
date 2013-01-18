function mtPaths_ = dtiLoadMetrotracPathsFromStrVer3(str,i, numstats, mtPaths,xform)
% Loads version 3 pdb file
%
%   mtPaths_ = dtiLoadMetrotracPathsFromStrVer3(str,i, numstats,mtPaths,xform)
%
% str is the string buffer
% i is the current position in the string buffer
% numstats is the number of statistics in the pdb
% It appears that xform is never used.
%
% HISTORY:
% 2010.08.01 
%
% Stanford VISTA
%
%% 

% profile on

% Boolean.  Only Matlab transform what?  Appears to always be false and
% thus the code below is not used.

% How many bytes for int32 and double
int32size   = size(typecast(int32(0),'uint8'),2);
doublesize = size(typecast(double(0.0),'uint8'),2);


numpaths = typecast( uint8(str(i:i+int32size-1)),'uint32'); 
i = i + int32size;
points_per_fiber = typecast( uint8(str(i:i+int32size*numpaths-1)),'int32'); i = i + int32size*numpaths;

% compute the total number of points
total_pts = 0;
for k = 1:numpaths
    total_pts = total_pts + points_per_fiber(k);
end
total_pts = uint32(total_pts);

% read all the fiber points
fiber_points = typecast( uint8(str(i:i+doublesize*total_pts*3-1)),'double'); 
i = i + doublesize*total_pts*3;
points_read = 0;

%% Reading each pathway
for p = 1:numpaths    
    numnodes = points_per_fiber(p);
    mtPaths.pathwayInfo(p).algo_type = 0; % algo type
    mtPaths.pathwayInfo(p).seed_point_index = 1; % seedpointindex ???
    
    % Reading path positions
    mtPaths.pathways{p,1} = fiber_points( 1+points_read*3 : (points_read+numnodes)*3);
    mtPaths.pathways{p,1} = reshape(mtPaths.pathways{p,1},3,numnodes);
    points_read = points_read + numnodes;

    if mod(p,10000)==0
        disp(['Loaded ' num2str(p) ' of ' num2str(numpaths)]);
    end
end

% Transform all fiber coords in one go (much faster!)
% I don't know why this offset is still necessary, isn't ACPC space all
% ACPC space??
bOnlyMatlabXForm=0;   % It appears that this is always false and could be deleted. 
if( ~bOnlyMatlabXForm )
    xformToMatlab = eye(4);
    xformToAcpc = xformToMatlab*mtPaths.xform;
    if isfield(mtPaths,'pathways')
        mtPaths.pathways = dtiXformFiberCoords(mtPaths.pathways, xformToAcpc);
    else
        mtPaths.pathways = [];
        mtPaths.pathwayInfo = [];
    end
end

%% Read per fiber stats
for as = 1:numstats
    per_fiber_stat = typecast( uint8(str(i:i+doublesize*numpaths-1)),'double'); 
    i = i + doublesize*numpaths;
    for p = 1:numpaths
        mtPaths.pathwayInfo(p).pathStat(as) = per_fiber_stat(p);

    end
end
%% Read per point stats
for as = 1:numstats
    if(mtPaths.statHeader(as).is_computed_per_point)
        per_point_stat = typecast( uint8(str(i:i+doublesize*total_pts-1)),'double'); 
        i = i + doublesize*total_pts; 
    end
    
    points_read = 0;
    % Assign per point stats value
    for p = 1:numpaths
        if(mtPaths.statHeader(as).is_computed_per_point)
            mtPaths.pathwayInfo(p).point_stat_array(as,:) = ...
                per_point_stat(points_read+1 : points_read+points_per_fiber(p));
            points_read = points_read + points_per_fiber(p);
        end
    end
end
mtPaths_ = mtPaths;

% profile off

end


