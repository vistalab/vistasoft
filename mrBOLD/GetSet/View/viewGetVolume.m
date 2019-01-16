function val = viewGetVolume(vw,param,varargin)
% Get data from various view structures
%
% This function is wrapped by viewGet. It should not be called by anything
% else other than viewGet.
%
% This function retrieves information from the view that relates to a
% specific component of the application.
%
% We assume that input comes to us already fixed and does not need to be
% formatted again.

if notDefined('vw'), vw = getCurView; end
if notDefined('param'), error('No parameter defined'); end

mrGlobals;
val = [];


switch param
    
    case 'nodes'
        % Return the array of nodes. Only gray views have nodes. See help
        % for mrManDist.m for a description of the node structure. In
        % brief, nodes are 8 x nvoxels. The first 3 rows correspond to the
        % voxel location and the next 5 correspond to gray graph-related
        % data.
        %   nodes = viewGet(vw, 'nodes');
        if isfield(vw, 'nodes'), val = vw.nodes;
        else
            val = [];
            warning('vista:viewError', 'Nodes not found.');
        end
    case 'xyznodes'
        % Return the xyz coordinates of the gray voxels as found in nodes
        % array. Assumes a Gray view. See case 'nodes' and help for
        % mrManDist for more information.
        %
        % Must call this sagittal, axial coronal or whatever the mapping is
        % ras, 06/07 -- I believe it's [cor axi sag]. coords is [axi cor sag].
        %
        % xyzNodes = viewGet(vw, 'xyz nodes');
        nodes = viewGet(vw,'nodes');
        val = nodes(1:3,:);
    case 'nodegraylevel'
        % Return the gray level of each voxel as determined by the nodes
        % array. Assumes a Gray view. See case 'nodes' and help for
        % mrManDist for more information.
        %   nodeGrayLevel = viewGet(vw, 'gray level');
        nodes = viewGet(vw,'nodes');
        val = nodes(6,:);
    case 'nnodes'
        % Return the number of nodes. Assumes a Gray view. See case 'nodes'
        % and help for mrManDist for more information.
        %   nNodes = viewGet(vw, 'number of nodes');
        val = size( viewGet(vw, 'nodes'), 2 );
    case 'edges'
        % Return the edge structure of the gray graph. Assumes a Gray view.
        % See help for mrManDist for more information.
        %   edges = viewGet(vw, 'edges');
        if isfield(vw, 'edges'), val = vw.edges;
        else val = []; warning('vista:viewError', 'Edges not found.'); end
    case 'nedges'
        % Return the number of edges in the gray graph. Assumes a Gray
        % view. See case 'edges' and help for mrManDist for more
        % information.
        %   nEdges = viewGet(vw, 'number of edges');
        val = length( viewGet(vw, 'edges') );
    case 'allleftnodes'
        % Return the subset of nodes in the Gray graph that are in the left
        % hemisphere. See mrgGrowGray and mrManDist.
        %   allLeftNodes = viewGet(vw, 'all left nodes');
        val = vw.allLeftNodes;
    case 'allleftedges'
        % Return the subset of edges in the Gray graph that are in the left
        % hemisphere. See mrgGrowGray and mrManDist.
        %   allLeftEdges = viewGet(vw, 'all left edges');
        val = vw.allLeftEdges;
        if isempty(val) && Check4File('Gray/coords')
            % Try laoding from the Gray/coords file
            load('Gray/coords', 'allLeftEdges')
            val = allLeftEdges;
        end
    case 'allrightnodes'
        % Return the subset of nodes in the Gray graph that are in the
        % right hemisphere. See mrgGrowGray and mrManDist.
        %   allRightNodes = viewGet(vw, 'all right nodes');
        val = vw.allRightNodes;
        if isempty(val) && Check4File('Gray/coords')
            % Try laoding from the Gray/coords file
            load('Gray/coords', 'allRightNodes')
            val = allRightNodes;
        end
        
    case 'allrightedges'
        % Return the subset of edges in the Gray graph that are in the
        % right hemisphere. See mrgGrowGray and mrManDist.
        %   allRightEdges = viewGet(vw, 'all right edges');
        val = vw.allRightEdges;
        
    case 'allnodes'
        % Return all nodes from Gray graph by taking union of allLeftNodes
        % and allRightNodes.
        %
        % This is NOT necessarily the same as simply returning 'vw.nodes'.
        % When we install a segmentation, we can either keep all the nodes
        % in the gray graph, or only those that fall within the functional
        % field of view (to save space). When we do the latter, the fields
        % vw.coords, vw.nodes, and vw.edges contain only the coords, nodes,
        % and eges within the functional field of view. However the fields
        % vw.allLeftNodes, vw.allLeftEdges, vw.allRightNodes, and
        % vw.allRightEdges contain the edges and nodes for the entire
        % hemisphere
        %
        % Example: nodes = viewGet(vw, 'all nodes');
        val = [vw.allLeftNodes'; vw.allRightNodes']';
        
        
    case 'alledges'
        % Return all edges from Gray graph by taking union of allLeftEdges
        % and allRightEdges. See 'allnodes' for explanation.
        %
        % Example: edges = viewGet(vw, 'all edges');
        val = [vw.allLeftEdges vw.allRightEdges];
        
    case 'coords'
        % Return all the coordinates in the current view. If in Flat view,
        % return the coordinates for a particular slice (slice specified in
        % varargin{1}). If in Inplane view, slice specification is
        % optional. If in Gray or Volume view, slice specification is
        % ignored.
        %   <gray, volume or inplane>
        %       coords = viewGet(vw, 'coords');
        %   <flat or inplane>
        %       slice  = viewGet(vw, 'current slice');
        %       coords = viewGet(vw,'coords', slice);
        try
            switch lower(viewGet(vw, 'viewType'))
                case 'flat'
                    %% separate coords for each flat hemisphere
                    if length(varargin) ~= 1
                        error('You must specify which hemisphere.');
                    end
                    hname = varargin{1};
                    switch hname
                        case 'left'
                            val = vw.coords{1};
                        case 'right'
                            val = vw.coords{2};
                        otherwise
                            error('Bad hemisphere name');
                    end
                case {'gray', 'volume', 'hiddengray'}
                    val = vw.coords;
                case 'inplane'
                    % These coords are for inplane anat. Functional coords
                    % may have different values (if
                    % upSampleFactor(vw,scan) ~= 1)
                    dims = viewGet(vw, 'anatomysize');
                    if length(varargin) >= 1  % then we want coords for just one slice
                        slice = varargin{1};
                        indices = 1+prod([dims(1:2) slice-1]):prod([dims(1:2) slice]);
                        val=indices2Coords(indices,dims);
                    else
                        indices = 1:prod(dims);
                        val=indices2Coords(indices,dims);
                    end
            end
        catch ME
            val=[];
            warning(ME.identifier, ME.message);
            fprintf('[%s]: Coords not found.', mfilename);
        end
        
    case 'allcoords'
        % Return all coords from Gray graph, including those that are not
        % included in the functional field of view. See 'allnodes' for
        % explanation. If session was initialized with the option
        % 'keepAllNodes' == true, then this call will be identical to
        % viewGet(vw.coords). 
        %
        % Optional input: hemi ('right' 'left' 'both') for right, left or both
        %
        % Example: coords = viewGet(vw, 'allcoords', 'right');
        nodes = viewGet(vw, 'nodes');
        
        if length(varargin) ~= 1
            hname = 'both';
        else
            hname = varargin{1};
        end
        
        switch hname
            case 'left'
                subnodes  = viewGet(vw, 'all left nodes');
                [~, ia] = intersectCols(nodes(1:3,:), subnodes(1:3,:));
            case 'right'
                subnodes  = viewGet(vw, 'all right nodes');
                [~, ia] = intersectCols(nodes(1:3,:), subnodes(1:3,:));
            otherwise
                ia = 1:size(nodes,2);
        end
         
        val = nodes([2 1 3], ia);
        
    case 'coordsfilename'
        % Return the path to the file in which coordinates are stored.
        % Assumes that a gray view has been created (though current view
        % can be any type).
        %   coordsFileName = viewGet(vw, 'coords file name');
        homeDir = viewGet(vw, 'homedir');
        if isempty(homeDir), val = ['Gray' filesep 'coords.mat'];
        else val = [homeDir filesep 'Gray' filesep 'coords.mat'];
        end
    case 'ncoords'
        % Return the number of coordinates in the current view. See case
        % 'coords'.
        %   nCoords = viewGet(vw, 'number of coords');
        val = size( viewGet(vw, 'Coords'), 2 );
        
    case 'classfilename'
        % Return the path to either the left or the right gray/white
        % classification file.
        %   fname = viewGet(vw, 'class file name', 'left');
        %   fname = viewGet(vw, 'class file name', 'right');
        if (length(varargin) == 1), hemisphere = varargin{1};
        else  hemisphere = 'left';
        end
        switch lower(hemisphere)
            case {'left' 'l'}
                if ~checkfields(vw,'leftClassFile') || isempty(vw.leftClassFile);
                    [~,val] = GetClassFile(vw, 0, 1);
                else
                    val = vw.leftClassFile;
                end
            case {'right' 'r'}
                if ~checkfields(vw,'rightClassFile') || isempty(vw.rightClassFile)
                    [~,val] = GetClassFile(vw, 1, 1);
                else
                    val = vw.rightClassFile;
                end
            otherwise
                error('Unknown hemisphere');
        end
        
    case {'classdata','class','classification','whitematter'}
        % classFileRight = viewGet(vw,'class data','right');
        if length(varargin) == 1, hemisphere = varargin{1};
        else error('You must specify right/left hemisphere.');
        end
        switch lower(hemisphere)
            case 'left'
                val = GetClassFile(vw, 0);
            case 'right'
                val = GetClassFile(vw, 1);
            otherwise
                error('Unknown hemisphere');
        end
        
    case {'graymatterfilename','graypath','grayfilename','grayfile'}
        % grayFile = viewGet(vw,'Gray matter filename','right');
        if length(varargin) == 1, hemisphere = varargin{1};
        else error('You must specify right/left hemisphere.');
        end
        switch lower(hemisphere)
            case 'left'
                if checkfields(vw,'leftPath')
                    val = vw.leftPath;
                end
            case 'right'
                if checkfields(vw,'rightPath')
                    val = vw.rightPath;
                end
            otherwise
                error('Unknown hemisphere');
        end
        
    otherwise
        error('Unknown viewGet parameter');
        
end

return
