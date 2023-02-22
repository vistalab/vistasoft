function view = meshGrowROI(view, name, startCoord, mask);
% Grow an ROI along the cortical surface, starting at the mesh cursor
% position and extending along a contiguous patch defined by the data in
% mask.
%
%  view = meshGrowROI([view], [name], [startCoord=cursor position], [mask=data overlay mask]);
%
% INPUTS:
%	view: mrVista gray view. [Defaults to selected gray.]
%
%	name: name of the new ROI. [Default is to call it 'Mesh ROI' with the
%	start coord appended.]
%
%	startCoord: coordinate of starting gray matter node. [Defaults to
%	position of cursor in currently-selected mesh.]
%
%	mask: binary data mask, size 1 x nNodes, indicating whether a given
%	node is acceptable to be included in the ROI. nNodes is the size of 
%	view.coords and view.nodes. If the start node is not 1, will warn the
%	user and exit without making an ROI. Will grow the ROI along the
%	view.edges field until there are no neighboring nodes for which mask is
%	1. [default: makes this mask based on the current mesh overlay and view
%	settings: if there is data shown on the overlay, the mask is 1; if not,
%	it's 0.]
%
% OUTPUTS:
%	view with a new ROI added (if one could be created).
%
% NOTE: This function uses iteration, and so if the data mask is mostly
% ones (the ROI has to grow a lot), the function can be memory
% intensive / may fail to finish due to the MATLAB iteration limit. Also,
% growing along the cortical surface is different from growing in the
% volume space. It is sensitive to the alignment/segmentation, so those
% should be in good order before this can be trusted.
%
% Finally, if you move the mesh (Ctrl + moving the mouse), this can mess up
% the correspondence between the mesh cursor position and the volume nodes.
% So, you can''t do that and have this keep working. (If you do this by
% accident, but you've saved some view settings, you can restore those
% settings and things should work again.)
%
% ras, 10/17/2008.
if notDefined('view'),		view = getSelectedGray;		end

%% data / mesh checks
if ~ismember(view.viewType, {'Gray' 'Volume'})
	error('Only works on Gray / Volume views.');
end

if ~isfield(view, 'mesh') | isempty(view.mesh)
	error('Need a mesh loaded.')
end

m = view.meshNum3d;
if m==0
	error('Need a selected mesh.')
end

if notDefined('startCoord'),	
	startCoord = meshCursor2Volume(view, view.mesh{m});
end

if notDefined('name'),		
	name = ['Mesh ROI ' num2str(startCoord)];
end

if notDefined('mask')
% 	[view mask] = meshColorOverlay(view, 0);
	mask = logical( ones(1, size(view.coords, 2)) );
	if length(view.co) >= view.curScan & ~isempty(view.co{view.curScan})
		co = view.co{view.curScan};
		mask = mask & (co > getCothresh(view));
	end
	if length(view.ph) >= view.curScan & ~isempty(view.ph{view.curScan})
		ph = view.ph{view.curScan};		
		phWin = getPhWindow(view);
		mask = mask & (ph >= phWin(1)) & (ph <= phWin(2));
	end
	if length(view.map) >= view.curScan & ~isempty(view.map{view.curScan})
		map = view.map{view.curScan};
		mapWin = getMapWindow(view);
		mask = mask & (map >= mapWin(1)) & (map <= mapWin(2));
	end
end

% get gray matter node corresponding to the start coord
startNode = roiIndices(view, startCoord(:));

% does the start node pass the criterion? If not, we shouldn't make an ROI
% with it:
if mask(startNode)==0
	myWarnDlg('The selected start point doesn''t pass the threshold.');
	return
end

%% initialize an empty ROI
ROI = roiCreate1;
ROI.name = name;
ROI.comments = sprintf(['Created by %s grown from seed %s'], mfilename, ...
						num2str(startCoord));
					
%% main part: "grow" coords in ROI (recursive)
h = msgbox('Growing Mesh ROI', mfilename);
nodes = growMeshROICoords(startNode, view, mask);
close(h);

ROI.coords = view.coords(:,nodes);

%% add ROI to view					
view = addROI(view, ROI);

return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function nodes = growMeshROICoords(nodes, view, mask);
% recursive function designed to grow mesh ROI coordinates.
% The logic here is: the nodes passed in are all voxels that will
% definitely be included in the mesh ROI. The code looks at neighboring
% voxels (according to the gray matter nodes/edges), evalautes them for
% inclusion (mask==1), and selects those which pass the test. 
% If there are any of these neighbors, the function is called again, now 
% looking at the neighbors of these neighbors.

%% find neighbors of the input nodes
neighbors = [];
for n = nodes
	nEdges = view.nodes(4,n);
	startEdge = view.nodes(5,n);
	neighbors = [neighbors view.edges(startEdge:startEdge+nEdges-1)];
end

%% which neighbors are contained in the mask?
neighbors = neighbors(mask(neighbors)==1);

% prevent the recursion from bouncing back and forth:
% some of these neighbors may already be included in nodes. Remove them;
% they're obviously okay. 
% (If I didn't do this, then if A points to B, and B points to A, and both
% satisfy the criteria, the function would keep getting called, first with
% A as the neigbor, then B, then A, etc...)
neighbors = setdiff(neighbors, nodes);

%% do any neighbors pass the test?
% if no, we're done. If yes, we recurse: call this function on the existing 
% nodes plus the neighbors:
if ~isempty(neighbors)
	nodes = growMeshROICoords([nodes neighbors], view, mask);
end
	
return

