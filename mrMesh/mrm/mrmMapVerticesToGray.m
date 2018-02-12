function [v2gMap, sqDist] = mrmMapVerticesToGray(vertexCoords, grayNodes, mmPerVox, grayEdges,distThresh)
%
% [v2gMap sqDist] = mrmMapVerticesToGray(vertices, grayNodes, mmPerVox, [grayEdges]);
%
% Finds a map between the mesh vertices and gray nodes.
% To see the coordinates of the gray matter node (or nodes) nearest to  
% mesh vertex I, we can use:
%    
%      nearestNodeCoords = grayNodes(1:3, v2gMap(:,I))
%
%
% If the grayEdges are also passed in, then we'll compute the mapping for
% all gray layers. Layer 1 mapping will be in the first row, and layers
% >1 in subsequent columns. As always, vertices with no mapping will be set
% to 0.
%
% The vertexGrayMap now has multiple rows to represent mappings from
% each vertex (the columns) to all gray layers. This mapping is computed in
% two steps:
%
% 1. For each vertex, find the nearest layer 1 gray node, where 'nearest'
% is simply the smallest 3d Euclidian distance, with a threshold to leave
% vertices that are too far from any layer 1 nodes unmapped (zero entry in
% vertexGrayMap). This threshold is currently set to 4mm- edit
% mrmMapVerticesToGray if you want to change this. This layer-1 mapping
% forms the first column of the vertexGrayMap. 
%
% 2. For each vertex (row), find all the nodes from layers >1 that should
% map to this vertex. This is a somewhat ill-posed problem, so we had to
% make a choice about which solution we wanted. We decided to use the gray
% layer connections to find all the layer >1 nodes that form a direct
% connection to the nearest layer 1 node that we mapped in step 1. As you
% discovered, this gives us a very redundant sampling of the gray nodes.
% The number of nodes >1 that are most directly connected to a given layer
% 1 node can be very high, especially in regions of high convexity. The
% algorithm for doing this essentially starts at the highest layers and
% maps them down to the most direct (ie. shortest path) layer 1 node. In a
% region of GM at the end of a thick finger of WM, this can map many nodes
% to one layer 1 node (apparently 84 in one case). The vertexGrayMap is an
% array, so the number of columns represents the most densely connected
% case. If you look at it, there are probably only a few vertices with as
% many as 84 connections. Most vertices probably have lots of zeros in
% those higher columns. In fact, in regions of high concavity, you should
% see some with no layers >1 (ie. a row with all zeros except for the first
% column).
%
% We realize that this choice of implementation might not be what everyone
% wants. But it works pretty well for our purposes. Of course, one downside
% to the highly redundant mapping is an effective 'smoothing' of the data,
% especially when you choose to average all layers (in your 3d window
% preferences settings). What we do is look at our data collapsed across
% layers as well as combining all layers, just to make sure we aren't
% missing something. 

%
% HISTORY:
%  2003.09.16 RFD (bob@white.stanford.edu)
%  2004.05.21 RFD: now uses Dan Merget's nearpoints to find a proper
%  mapping. No more hacks! Aside from being a bit faster, the result should
%  be substantially more accurate.
%  2005.07.26 RFD: We now return a mapping for all gray layers, if
%  grayEdges is passed in.
%  2005.08.05 RFD: all gray layer mapping is turned off by default, until
%  we figure out how to make it go faster.
%  2005.10.26 GB: Tentative speed improvement in the main loop
%  2006.06.01 RFD: added comments above. These were prompted by an email
%  exchange with David Ress.
%  2007.05.23 ARW : Gray layer mapping seems to be available. Which is
%  nice. Added some minor mods to return sqDist and detect dist thresholds.
verbose = prefsVerboseCheck;

if notDefined('mmPerVox'), error('Voxel size (mm per vox) is required.'); end;
if (notDefined('distThresh'))
    if (ispref('VISTA','defaultSurfaceWMMapDist'))
		if verbose,	
	        disp('Setting distThresh to the one in VISTA preferences');
		end
        distThresh = getpref('VISTA','defaultSurfaceWMMapDist');
    else
       if verbose, disp('Setting distThresh to 2'); end
       distThresh = 3;
    end
end

vertexCoords = double(vertexCoords);
grayNodes = double(grayNodes);

if notDefined('grayEdges')
    grayEdges=[];
end

grayEdges = double(grayEdges);

prefs = mrmPreferences;
if(strcmp(prefs.layerMapMode,'all'))
    mapToAllLayers = true;
else
    mapToAllLayers = false;
end

% This is now a real distance threshold, in mm. For each mesh vertex, the
% algorithm will find the nearest gray coord. If the nearest coord is >
% distThresh from the vertex, then that vertex gets no mapping ('0'). 

% The gray coordinates are in voxels in the vAnatomy file.  This scales
% them into real physical (mm) coordinates.  And transposes them.
grayCoords = grayNodes([1,2,3], :);
grayCoords = [grayCoords(1,:).*mmPerVox(1); ...
        grayCoords(2,:).*mmPerVox(2); ...
        grayCoords(3,:).*mmPerVox(3) ]';

% Transposes these mesh coordinates, which were already built in real
% physical coordinates.  
% Major comments needed here.
vertexCoords = vertexCoords' + 1;

% Mask out non-layer 1 nodes so that they are not found
if (~strcmp(prefs.layerMapMode,'any'))
	if verbose,     disp('Masking out layers > 1');   end
    grayCoords(grayNodes(6,:)~=1,:) = -9999;
end

[v2gMap, sqDist] = nearpoints(double(vertexCoords'), double(grayCoords'));

if verbose, 
	fprintf('Excluding mesh nodes further than %d away from the boundary \n', ...
			distThresh);
end

v2gMap(sqDist > (distThresh^2)) = 0;

v2gMap = int32(v2gMap);

if(mapToAllLayers && exist('grayEdges','var') && ~isempty(grayEdges))
    layer1Nodes = v2gMap;
    curValid = double(layer1Nodes) > 0;
    numLayers = max(grayNodes(6,:));
    n = length(curValid);
    curLayerNum = 2;

    % GB 2005.10.26
    % We map from higher layers to lower layers,
    % selecting the closest connected node in the lower layer. This way we
    % will avoid multiply-connected 

    noNeighborsDown = 0;
    noNeighbor = 0;
    noNeighbor2 = 0;
    
    v2gMapTemp = zeros(numLayers,size(grayNodes,2));
    
    h = mrvWaitbar(0, 'Computing between layers connections...');
    progress = 0;
    for iLayer = numLayers:-1:curLayerNum
        midprogress = 0;
        
        curNodes = find(grayNodes(6,:) == iLayer);
        for iNode = curNodes
            % disp(iNode) % debugging
            offset = grayNodes(5,iNode);
            numConnected = grayNodes(4,iNode);
            if numConnected == 0
                noNeighbor = noNeighbor + 1;
                continue %mrmMapVerticesToGray
            end
            neighbors = grayEdges(offset:offset + numConnected - 1);
            neighbors(grayNodes(6,neighbors) ~= (iLayer - 1)) = [];
            distance = sum(grayNodes(1:3,neighbors).^2,1);
            [value,nearest] = min(distance);
            if ~isempty(nearest)
                v2gMapTemp(iLayer,iNode) = neighbors(nearest);
            elseif length(nearest) > 1
                neighbors = neighbors(nearest);
                distanceIndex = abs(neighbors - iNode);
                [value,nearest] = min(distanceIndex);
                v2gMapTemp(iLayer,iNode) = neighbors(nearest);
            else
                neighbors = grayEdges(offset:offset + numConnected - 1);
                neighbors(grayNodes(6,neighbors) < iLayer - 1) = [];
                nextNeighbors = [];
                neighborsDown = [];
                iter = 0; % debugging
                while isempty(neighborsDown) && ~isequal(neighbors,nextNeighbors)
                    iter = iter+1; %debugging
                    if iter> 1000,
                       disp foo
                       break
                    end
                    neighbors = union(nextNeighbors,neighbors);
                    nextNeighbors = [];
                    for iNeighbor = 1:length(neighbors)
                        offset = grayNodes(5,neighbors(iNeighbor));
                        numConnected = grayNodes(4,neighbors(iNeighbor));
                        nextNeighbors = [nextNeighbors grayEdges(offset:offset+numConnected-1)];
                    end
                    nextNeighbors = unique(nextNeighbors);
                    neighborsDown = nextNeighbors(grayNodes(6,nextNeighbors) == (iLayer - 1));
                end
                
                if isempty(neighborsDown)
                    noNeighbor2 = noNeighbor2 + 1;
                else
                    distance = sum(grayNodes(1:3,neighborsDown).^2,1);
                    [value,nearest] = min(distance);
                    if length(nearest) == 1
                        v2gMapTemp(iLayer,iNode) = neighborsDown(nearest(1));
                    else
                        neighborsDown = neighborsDown(nearest);
                        distanceIndex = abs(neighborsDown - iNode);
                        [value,nearest] = min(distanceIndex);
                        v2gMapTemp(iLayer,iNode) = neighborsDown(nearest);
                    end
                end
                noNeighborsDown = noNeighborsDown + 1;
            end
        end
        progress = progress + 1/(numLayers - curLayerNum + 1);
        mrvWaitbar(progress/2,h);
    end
    
    indices = 2*ones(1,size(v2gMap,2));
    indexNodes = cell(1,size(grayNodes,2));
    for curNode = find(curValid)
        indexNodes{v2gMap(1,curNode)} = [indexNodes{v2gMap(1,curNode)} curNode];
    end
    
    h = mrvWaitbar(1/2, h, 'Creating connections table...');
    progress = 0;
    for iNode = 1:size(grayNodes,2)
        if iNode > (progress + 1/10)*size(grayNodes,2)
            progress = progress + 1/10;
            mrvWaitbar(0.5 + progress/2);
        end
        
        curLayer = grayNodes(6,iNode);
        curNode = iNode;
        for iLayer = curLayer:-1:2
            if curNode == 0
                break
            end
            curNode = v2gMapTemp(iLayer,curNode);
        end
        if (curNode == 0) || (curNode == iNode)
            continue
        end

        indexNode = indexNodes{curNode};
        if isempty(indexNode)
            continue
        end
        
        v2gMap(indices(indexNode),indexNode) = iNode;
        indices(indexNode) = indices(indexNode) + 1;
        
    end
    close(h);
 
end

return;
