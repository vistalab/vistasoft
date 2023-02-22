function val = fgGet(fg,param,varargin)
%Get values from a fiber group structure
%
%  val = fgGet(fg,param,varargin)
%
% Parameters
% General
%    'name'
%    'type'
%    'colorrgb'
%    'thickness'
%    'visible'
%
% Fiber related
%    'nfibers'- Number of fibers in this group
%    'nodes per fiber'  - Number of nodes per fiber.
%    'fibers' - Fiber coordinates
%    'fibernames'
%    'fiberindex'
%
% ROI and image coord related
%    'unique image coords'
%    'nodes to imagecoords' -
%    'voxel2fiber node pairs' - For each roi coord, an Nx2 matrix of
%        (fiber number,node number)
%    'nodes in voxels' - Nodes inside the voxels of roi coords
%    'voxels in fg'  - Cell array of the roiCoords touched by each fiber
%    'voxels2fibermatrix' - Binary matrix (voxels by fibers).  1s when a
%        fiber is in a voxel of the roiCoords (which are, sadly, implicit).
%
% Tensor and tractography related
%      'tensors'     - Tensors for each node
%
%
% See also: dwiGet/Set, fgCreate; fgSet
%
% (c) Stanford VISTA Team

% NOTES: 
% Programming TODO:
%   We should store the transforms needed to shift the fg coordinates
%   between acpc and image space.

% I eliminated these checks because this function is now called many many
% times and this slows the computations (Franco).
%
%if notDefined('fg'),error('fiber group required.'); end
% if notDefined('param'), error('param required.'); end

val = [];

switch mrvParamFormat(param)
  
  % Basic fiber parameters
  case 'name'
    val = fg.name;
  case 'type'  % Should always be fibergroup
    val = fg.type;
    
    % Fiber visualization settings.
  case 'colorrgb'
    val = fg.colorRgb;
  case 'thickness'
    val = fg.thickness;
  case 'visible'
    val = fg.visible;
    
    % Simple fiber properties --
  case {'fibers'}
    % val = fgGet(fg,'fibers',fList);
    %
    % Returns a 3xN matrix of fiber coordinates corresponding to the
    % fibers specified in the integer vector, fList.  This differs from
    % the dtiH (mrDiffusion) representation, where fiber coordinates
    % are stored as a set of cell arrays for each fiber.
    if ~isempty(varargin)
      list = varargin{1};
      val = cell(length(list),1);
      for ii=1:length(list)
        val{ii} = fg.fibers{ii};
      end
    else
      val = fg.fibers;
    end
  case 'fibernames'
    val = fg.fiberNames;
  case 'fiberindex'
    val = fg.fiberIndex;
  case 'nfibers'
    val = length(fg.fibers);
  case {'nodesperfiber','nsamplesperfiber','nfibersamples'}
    % fgGet(fg,'n samples per fiber ')
    % How many samples per fiber.  This is about equal to
    % their length in mm, though we need to write the fiber lengths
    % routine to actually calculate this.
    nFibers = fgGet(fg,'n fibers');
    val = zeros(1,nFibers);
    for ii=1:nFibers
      val(ii) = length(fg.fibers{ii});
    end
    
    % Fiber group (subgroup) properties.
    % These are used when we classify fibers into subgroups.  We should
    % probably clean up this organization which is currently
    %
    %   subgroup - length of fibers, an index of group identity
    %   subgroupNames()
    %    .subgroupIndex - Probably should go away and the index should
    %          just be
    %    .subgroupName  - Probably should be moved up.
    %
  case {'ngroups','nsubgroups'}
    val = length(fg.subgroupNames);
  case {'groupnames'}
    val = cell(1,fgGet(fg,'n groups'));
    for ii=1:nGroups
      val{ii} = fg.subgroupNames(ii).subgroupName;
    end
    
    % DTI properties
  case 'tensors'
    val = fg.tensors;
    
    % Fiber to coord calculations
  case {'imagecoords'}
    % c = fgGet(fgAcpc,'image coords',fgList,xForm);
    % c = fgGet(fgAcpc,'image coords',fgList,xForm);
    %
    % Return the image coordinates of a specified list of fibers
    % Returns a matrix that is fgList by 3 of the image coordinates for
    % each node of each fiber.
    %
    % Fiber coords are represented at fine resolution in ACPC space.
    % These coordinates are rounded and in image space
    if ~isempty(varargin)
      fList = varargin{1};
      if length(varargin) > 1
        xForm = varargin{2};
        % Put the fiber coordinates into image space
        fg = dtiXformFiberCoords(fg,xForm);
      end
    else
      % In this case, the fiber coords should already be in image
      % space.
      nFibers = fgGet(fg,'n fibers');
      fList = 1:nFibers;
    end
    
    % Pull out the coordinates and floor them.  These are in image
    % space.
    nFibers = length(fList);
    val = cell(1,nFibers);
    if nFibers == 1
      %val = round(fg.fibers{fList(1)}');      
      val = floor(fg.fibers{fList(1)}');

    else
      for ii=1:nFibers
        %val{ii} = round(fg.fibers{fList(ii)}');     
        val{ii} = floor(fg.fibers{fList(ii)}');

      end
    end
    
  case {'uniqueimagecoords'}
    %   coords = fgGet(fgIMG,'unique image coords');
    %
    % The fg input must be in IMG space.
    %
    % Returns the unique image coordinates of all the fibers as an Nx3
    % matrix of integers.
    % val = round(horzcat(fg.fibers{:})'); 
    val = floor(horzcat(fg.fibers{:})');
    val = unique(val,'rows');
    
  case {'nodes2voxels'}
    %   nodes2voxels = fgGet(fgImg,'nodes2voxels',roiCoords)
    %
    % The roiCoords are a matrix of Nx3 coordinates.  They describe a
    % region of interest, typically in image space or possibly in acpc
    % space.
    %
    % We return a cell array that is a mapping of fiber nodes to voxels in
    % the roi.  The roi is specified as an Nx3 matrix of coordinates.
    % The returned cell array, nodes2voxels, has the same number of
    % cells as there are fibers.
    %
    % Unlike the fiber group cells, which have a 3D coordinate of each
    % node, this cell array has an integer that indexes the row of
    % roiCoords that contains the node. If a node is not in any of the
    % roiCoords, the entry in node2voxels{ii} for that node is zero.
    % This means that node is outside the 'roiCoords'.
    %
    % Once again: The cell nodes2voxels{ii} specifies whether each
    % node in the iith fiber is inside a voxel in the roiCoords.  The
    % value specifies the row in roiCoords that contains the node.
    %
    if isempty(varargin), error('roiCoords required');
    else
      roiCoords = varargin{1};
    end
    
    % Find the roiCoord for each node in each fiber.
    nFiber = fgGet(fg,'n fibers');
    val    = cell(nFiber,1);
    for ii=1:nFiber
      % if ~mod(ii,200), fprintf('%d ',ii); end
      % Node coordinates in image space
      nodeCoords = fgGet(fg,'image coords',ii);
      
      % The values in loc are the row of the coords matrix that contains
      % that sample point in a fiber.  For example, if the number 100 is
      % in the 10th position of loc, then the 10th sample point in the
      % fiber passes through the voxel in row 100 of coords.
      [~, val{ii}] = ismember(nodeCoords, roiCoords, 'rows');
    end
    
  case {'voxel2fibernodepairs','v2fn'}
    % voxel2FNpairs = fgGet(fgImg,'voxel 2 fibernode pairs',roiCoords);
    % voxel2FNpairs = fgGet(fgImg,'voxel 2 fibernode pairs',roiCoords,nodes2voxels);
    %
    % The return is a cell array whose size is the number of voxels.
    % The cell is a Nx2 matrix of the (fiber, node) pairs that pass
    % through it.
    %
    % The value N is the number of nodes in the voxel.  The first
    % column is the fiber number.  The second column reports the indexes
    % of the nodes for each fiber in each voxel.
    tic
    fprintf('\n[fgGet] Computing fibers/nodes pairing in each voxel...')
    if length(varargin) < 1, error('Requires the roiCoords.');
    else
      roiCoords = varargin{1};
      nCoords = size(roiCoords,1);
    end
    if length(varargin) < 2
      % We assume the fg and the ROI coordinates are in the same
      % coordinate frame.
      nodes2voxels    = fgGet(fg,'nodes 2 voxels',roiCoords);
    else nodes2voxels = varargin{2};
    end
    
    nFibers      = fgGet(fg,'nFibers');
    voxelsInFG   = fgGet(fg,'voxels in fg',nodes2voxels);
    roiNodesInFG = fgGet(fg,'nodes in voxels',nodes2voxels);
    val = cell(1,nCoords);
    for thisFiber=1:nFibers
      voxelsInFiber = voxelsInFG{thisFiber};   % A few voxels, in a list
      nodesInFiber  = roiNodesInFG{thisFiber}; % The corresponding nodes
      
      % Then add a row for each (fiber,node) pairs that pass through
      % the voxels for this fiber.
      for jj=1:length(voxelsInFiber)
        thisVoxel = voxelsInFiber(jj);
        % Print out roi coord and fiber coord to verify match
        % roiCoords(thisVoxel,:)
        % fg.fibers{thisFiber}(:,nodesInFiber(jj))
        % Would horzcat be faster?
        val{thisVoxel} = cat(1,val{thisVoxel},[thisFiber,nodesInFiber(jj)]);
      end
    end
    fprintf('process completed in: %2.3fs.\n',toc)

  case {'nodesinvoxels'}
    % nodesInVoxels = fgGet(fg,'nodes in voxels',nodes2voxels);
    %
    % This cell array is a modified form of nodes2voxels (see above).
    % In that cell array every node in every fiber has a number
    % referring to its row in roiCoords, or a 0 when the node is not in
    % any roiCoord voxel.
    %
    % This cell array differs only in that the 0s removed.  This
    % is used to simplify certain calculations.
    %
    if length(varargin) <1
      error('Requires nodes2voxels cell array.');
    end
    
    nodes2voxels = varargin{1};
    nFibers = fgGet(fg,'nFibers');
    val = cell(1,nFibers);
    
    % For each fiber, this is a list of the nodes that pass through
    % a voxel in the roiCoords
    for ii = 1:nFibers
      % For each fiber, this is a list of the nodes that pass through
      % a voxel in the roiCoords
      lst = (nodes2voxels{ii} ~= 0);
      val{ii} = find(lst);
    end
    
  case 'voxelsinfg'
    % voxelsInFG = fgGet(fgImg,'voxels in fg',nodes2voxels);
    %
    % A cell array length n-fibers. Each cell has a list of the voxels
    % (rows of roiCoords) for a fiber.
    %
    % This routine eliminates the 0's in the nodes2voxels lists.
    %
    if length(varargin) < 1, error('Requires nodes2voxels cell array.'); end
    
    nodes2voxels = varargin{1};
    nFibers = fgGet(fg,'nFibers');
    val = cell(1,nFibers);
    for ii = 1:nFibers
      % These are the nodes that pass through a voxel in the
      % roiCoords
      lst = (nodes2voxels{ii} ~= 0);
      val{ii} = nodes2voxels{ii}(lst);
    end
    
  case {'voxels2fibermatrix','v2fm'}
    %   v2fm = fgGet(fgImg,'voxels 2 fiber matrix',roiCoords);
    % Or,
    %   v2fnPairs = fgGet(fgImg,'v2fn',roiCoords);
    %   v2fm = fgGet(fgImg,'voxels 2 fiber matrix',roiCoords, v2fnPairs);
    %
    % mrvNewGraphWin; imagesc(v2fm)
    %
    % Returns a binary matrix of size Voxels by Fibers.
    % When voxel ii has at least one node from fiber jj, there is a one
    % in v2fm(ii,jj).  Otherwise, the entry is zero.
    %
    
    % Check that the fg is in the image coordspace:
    if isfield(fg, 'coordspace') && ~strcmp(fg.coordspace, 'img')
      error('Fiber group is not in the image coordspace, please xform');
    end
    
    if isempty(varargin), error('roiCoords required');
    else
      roiCoords = varargin{1};
      nCoords   = size(roiCoords,1);
      if length(varargin) < 2
        v2fnPairs = fgGet(fg,'v2fn',roiCoords);
      else
        v2fnPairs = varargin{2};
      end
    end
    
    % Allocate matrix of voxels by fibers
    val = zeros(nCoords,fgGet(fg,'n fibers'));
    
    % For each coordinate, find the fibers.  Set those entries to 1.
    for ii=1:nCoords
      if ~isempty(v2fnPairs{ii})
        f = unique(v2fnPairs{ii}(:,1));
      end
      val(ii,f) = 1;
    end
    
  case {'fibersinroi','fginvoxels','fibersinvoxels'}
    % fList = fgGet(fgImg,'fibersinroi',roiCoords);
    %
    % v2fn = fgGet(fgImg,'v2fn',roiCoords);
    % fList = fgGet(fgImg,'fibersinroi',roiCoords,v2fn);
    %
    % Returns an integer vector of the fibers with at least
    % one node in a region of interest.
    %
    % The fg and roiCoords should be in the same coordinate frame.
    %
    if isempty(varargin), error('roiCoords required');
    elseif length(varargin) == 1
      roiCoords = varargin{1};
      v2fnPairs = fgGet(fg,'v2fn',roiCoords);
    elseif length(varargin) > 1
      roiCoords = varargin{1};
      v2fnPairs = varargin{2};
    end
    
    val = []; nCoords = size(roiCoords,1);
    for ii=1:nCoords
      if ~isempty(v2fnPairs{ii})
        val = cat(1,val,v2fnPairs{ii}(:,1));
      end
    end
    val = sort(unique(val),'ascend');
    
  case {'coordspace','fibercoordinatespace','fcspace'}
    % In some cases, the fg might contain information telling us in which
    % coordinate space its coordinates are set. This information is set
    % as a struct. Each entry in the struct can be either a 4x4 xform
    % matrix from the fiber coordinates to that space (with eye(4) for
    % the space in which the coordinates are defined), or (if the xform
    % is not know) an empty matrix.
    
    cspace_fields = fields(fg.coordspace);
    val = [];
    for f=1:length(cspace_fields)
      this_field = cspace_fields{f};
      if isequal(getfield(fg.coordspace, this_field), eye(4))
        val = this_field;
      end
    end
    
  otherwise
    error('Unknown fg parameter: "%s"\n',param);
end

return
