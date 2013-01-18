function ui = mrViewROI(command, ui, varargin);
% ROI Editing and Display functions for mrViewer.
%
% ui = mrViewROI(command, ui, [options]);
%
% [The format is a bit of a break from the usual way of
% specifying the ui first, b/c the ui is usually omitted
% and the active one found w/ mrViewGet, but the command
% is always necessary]
%
% This function incorporates several small commands, which interact
% between the ROI tools and the mrViewer GUI. The commands are:
%   'new': create a new empty ROI
%
%   'add': add coords to the ROI, according to the current edit mode
%
%   'remove': remove coords from the ROI, according to the curr edit mode
%
%   'delete': delete an ROI, prompting with a dialog if one isn't specified
%
%   'draw': re-draw rois according to current view settings
%
%   'edit': edit selected ROI properties
%
%   'select': set selected ROI. If an extra 3rd argument is passed, which
%             is either an index into the ROI list, or a name of an ROI,
%             will select that ROI. Otherwise will select based on the
%             ROI select popup in the ROI panel.
%
%   'restrict': restrict ROI coordinates to within the overlays currently
%             being displayed. (Overlays in which the 'hide' option is
%             selected won't affect this.) mrView('restrict', ui, 'all')
%             will cause all ROIs to be restricted. Otherwise, the selected
%             ROI only will be restricted.
%
%   'load':   load a mrVista ROI into the viewer. The Session GUI must be
%             open for this.
%
%   'save':   save selected ROI in mrVista format. Will save as an Inplane
%             or Volume ROI, depending on the ROI's 'viewType' property.
%             (Edit the ROI to change this.)
%
%   'mesh':   If a mesh is opened, get the ROI points drawn on the mesh 
%             as a new ROI. An optional mapping argument can be specified,
%             which determines how to grab the mesh ROI: it can be 
%             'layer1', in which case only gray layer 1 nodes are drawn in the
%             new ROI, or 'all', in which case all layers are mapped. If
%             this option is omitted, defaults to using the 'layerMapMode'
%             pref in mrmPreferences.
%
%	'meshgrow': grow an ROI along the cortical surface, using the viewer's 
%			  overlay settings to determine the boundaries of the ROI. The
%			  ROI will be a contiguous patch on the cortical surface
%			  bounded by the overlay conditions. (Note that if no
%			  thresholding is specified, the code will warn you and not
%			  make an ROI.) By default the ROI is grown starting from the 
%			  mesh cursor. However, an alternate start coordinate can be 
%			  specified as an optional input argument.
%
%   'disk':   If a gray-matter segmentation is installed, create a disk
%             ROI along the gray matter. ('disc' also works.) An optional
%             size argument can be specified, which determines the radius
%             of the disc in mm. If omitted, prompts the user.
%
%   'gray':   Create ROI containing all gray matter nodes for the selected 
%             segmentation. (If a segmentation is loaded.)
%
% If called with no arguments, instead of returning a ui struct,
% mrViewROI will return the currently-selected ROI in the viewer.
%
% ras 08/05
if notDefined('ui'),        ui = mrViewGet;                         end
if ishandle(ui),            ui = get(ui, 'UserData');               end
if notDefined('command'),   ui = ui.rois(ui.settings.roi); return;  end

if ~isfield(ui,'display'), error('Need an active display');         end

% ras 03/07: I used to have a 'switch' command here, but it got pretty
% long, so I broke each command into its own subfunction to make finding a
% sub-command easier. This m-file has a lot of subfunctions! I'll probably
% move the dedicated ROI stuff (roi*Coords) to their own m-files soon...

% allow british spelling of the 'disk' command :)
if isequal(lower(command), 'disc'), command = 'disk'; end

% this switchyard will call the relevant sub-command functions 
subfun = sprintf('mrView%s%sROI', upper(command(1)), lower(command(2:end)));
% try
	ui = feval(subfun, ui, varargin);
% catch
% 	error('Unknown command.')
% end

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewNewROI(ui, varargin);
%%%%%Create a new, empty ROI (and select it)
roi = roiCreate(ui.mr, []);
roi.name = sprintf('ROI%i',length(ui.rois)+1);
roi.lineHandles = []; % for drawing ROIs
roi.prevCoords = []; % for undo
if isempty(ui.rois), ui.rois=roi; else, ui.rois(end+1)=roi; end
ui.settings.roi = length(ui.rois); % select it

% select the ROI 
mrViewROI('select', ui, length(ui.rois));
return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewAddROI(ui, varargin)
%%%%%Add to current ROI, using selected method
% If no rois exist, make a new one
if isempty(ui.rois), ui = mrViewROI('new',ui);    end

% get new coords using selected method
method = ui.settings.roiEditMode;
switch method
	case 1, coords = roiRectCoords(ui);
	case 2, coords = roiCircleCoords(ui);
	case 3, coords = roiCubeCoords(ui);
	case 4, coords = roiSphereCoords(ui);
	case 5, coords = roiLineCoords(ui);
	case 6, coords = roiPointCoords(ui);
	case 7, coords = roiGrowCoords(ui);
end

% round and remove redundant
coords = round(coords);
coords = intersectCols(coords, coords);

% add to ROI
roi = ui.rois(ui.settings.roi);
roi.coords = [roi.coords coords];
roi.coords = intersectCols(roi.coords, roi.coords); % rm redundant
roi.modified = datestr(clock);
ui.rois(ui.settings.roi) = roi;

% show changes
mrViewROI('draw',ui);

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewRemoveROI(ui, varargin);
%%%%%Remove points from current ROI, using selected method
% If no rois exist, exit quietly
if isempty(ui.rois), return;  end

% get coords to remove using selected method
method = ui.settings.roiEditMode;
switch method
	case 1, coords = roiRectCoords(ui);
	case 2, coords = roiCircleCoords(ui);
	case 3, coords = roiCubeCoords(ui);
	case 4, coords = roiSphereCoords(ui);
	case 5, coords = roiLineCoords(ui);
	case 6, coords = roiPointCoords(ui);
	case 7, coords = roiGrowCoords(ui);
end

% remove coords from ROI
roi = ui.rois(ui.settings.roi);
[ignore oldInd] = setdiff(roi.coords', coords', 'rows');
roi.coords = roi.coords(:,sort(oldInd)); % preserve voxel order
roi.modified = datestr(clock);
ui.rois(ui.settings.roi) = roi;

% show changes
mrViewROI('draw', ui);

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewDeleteROI(ui, varargin);
%%%%%Delete an ROI from the UI
varargin = unNestCell(varargin);
% (optional arg is list of ROIs to delete)
if isempty(varargin)
	delRoi = ui.settings.roi;
elseif isequal(lower(varargin{1}),'all')
	delRoi = 1:length(ui.rois);
else
	delRoi = varargin{1};
end

% if we don't have any ROIs and try to delete, don't sweat it
if isempty(ui.rois), return; end

% indices of non-deleted ROIs
newInd = setdiff(1:length(ui.rois), delRoi);

% figure out what the selected ROI index will be after we delete
if ismember(ui.settings.roi, delRoi) 
	% selected ROI was deleted -- select last one in list
	selRoi = length(newInd);
else
	% selected ROI was not deleted -- but its index may have
	% changed. Figure out the new index.
	selRoi = ui.rois(ui.settings.roi).name; % can select by name
end

% now, delete -- keep only non-deleted ROIs
ui.rois = ui.rois(newInd);

% set a new selected ROI
mrViewROI('select', ui, selRoi);
	
return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewLoadROI(ui);
%%%%%Load an ROI 
% mrVista 2, back-compatible version: load from GUI
sessionGUI_loadROI;
return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewSaveROI(ui, varargin);
%%%%%Save an ROI 
varargin = unNestCell(varargin);
% for now, we save to a back-compatible mrVista 1 format. 
if ~isempty(varargin) & isequal(varargin{1}, 'all')
	roiList = 1:length(ui.rois);
else
	roiList = ui.settings.roi;
end

for r = roiList
	mrViewSave(ui, r, 'roi');
end

% update the sessionGUI to include this ROI
sessionGUI_selectROIType;

return		
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewRestrictROI(ui, varargin);
%%%%%Restrict ROI(s) to within overlays
% (If no overlays, don't restrict -- would just delete ROI)
if isempty(ui.overlays), return; end

varargin = unNestCell(varargin);
if ~isempty(varargin) & isequal(lower(varargin{1}), 'all')
	roiList = 1:length(ui.rois);
else
	roiList = ui.settings.roi;
end

for r = roiList
	roi = ui.rois(r);
	hidden = [ui.overlays.hide];
	roi.coords = mrViewRestrict(ui, roi.coords, find(~hidden));
	roi.modified = datestr(clock);
	ui.rois(r) = roi;
end

% show changes
ui = mrViewROI('draw',ui);

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewEditROI(ui, varargin);
%%%%%Edit/view ROI traits, such as name/color
if isempty(ui.rois)
	myWarnDlg('No ROIs Created Yet.');
	return
end
roi = ui.rois(ui.settings.roi);
roi = roiEdit(roi);
ui.rois(ui.settings.roi) = roi;

% show changes (updating popup in this call)
try, ui = mrViewROI('draw', ui); end

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewDrawROI(ui, varargin);
%%%%%Draw rois on display
% delete any existing ROI lines
for ax = ui.display.axes
	delete(findobj('Parent', ax, 'Type', 'line', 'Tag', 'ROI'));
end

% get list of ROIs to draw, based on ROI view mode
if ui.settings.roiViewMode==1 | isempty(ui.rois)
	% hide ROIs, or no ROIs -- return quietly
	for r = 1:length(ui.rois)
		ui.rois(r).lineHandles = [];
	end
	set(ui.fig, 'UserData' ,ui);
	return
elseif ui.settings.roiViewMode==2 % show selected
	roiList = ui.settings.roi;
else,                              % show all
	roiList = 1:length(ui.rois);
end

% draw all selected ROIs on displayed images
for i = 1:length(ui.display.images)
	for r = roiList
		% find ROI points which may lie in image
		C = ui.rois(r).coords;
		if ui.settings.space==1
			% pixel space, use ROI coords directly
			if isempty(C), pts = [];
			else, pts = C(1:2,C(3,:)==ui.display.slices(i));
			end
		else
			% get ROI coords which correspond to imaged
			% region
			imgCoords = round(mrViewGet(ui,'DataCoords',i));
			[ignore ind] = intersectCols(imgCoords,C);
			imgSz = size(ui.display.images{i}); imgSz = imgSz(1:2);
			[rows cols] = ind2sub(imgSz,ind);
			AX = [get(ui.display.axes(i), 'XLim') ...
				  get(ui.display.axes(i), 'YLim')]; % will have to account for axis bounds
			pts = [rows+AX(3)-1 cols+AX(1)-1]';
		end

		% draw points, taking preferences into account
		if ~isempty(pts)
			prefs.color = ui.rois(r).color;
			prefs.axesHandle = ui.display.axes(i);
			prefs.method = cellfind({'perimeter' 'filled' 'patches'}, ...
									ui.rois(r).fillMode);
			if r==ui.settings.roi
				prefs.lineStyle = '-';
				prefs.lineWidth = 1;
				prefs.color = 'w';
			else
				prefs.lineStyle = ':';
				prefs.lineWidth = 0.2;
			end
			axes(ui.display.axes(i));
			ui.rois(r).lineHandles = outline(pts,prefs);
			set(ui.rois(r).lineHandles, 'Tag', 'ROI');
		end
	end
end

% update changes in UI
set(ui.fig, 'UserData', ui);

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewSelectROI(ui, varargin);
%%%%%Set selected ROI
% parse the ROI specification
varargin = unNestCell(varargin);
if isempty(varargin)  % get from selected ROI
	selRoi = get(ui.controls.roiSelect, 'Value');
elseif isnumeric(varargin{1}) % ROI index
	selRoi = varargin{1};
elseif ischar(varargin{1}) % ROI name
	selRoi = cellfind({ui.rois.name}, varargin{1});
else
	error('Invalid ROI specification.')
end

ui.settings.roi = selRoi;

% update selected ROI popup if it exists
ui = updateROIPopup(ui);

try,   mrViewROI('draw', ui);   end

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewMeshROI(ui, varargin);
%%%%%Get Mesh ROI
msh = mrViewGet(ui, 'CurMesh');
if isempty(msh), myErrorDlg('No Mesh Loaded.'); end
varargin = unNestCell(varargin);
if isempty(varargin)    % get map method via mrmPreferences
	prefs = mrmPreferences;
	mapMethod = lower(prefs.layerMapMode);
else
	mapMethod = lower(varargin{1}); 
end

seg = mrViewGet(ui, 'CurSegmentation');
roi = roiFromMesh(seg, mapMethod, ui.mr);
ui = mrViewSet(ui, 'NewROI', roi);
try,   mrViewROI('draw', ui);   end
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewMeshgrowROI(ui, varargin);
%%%%%Grow Mesh ROI along cortical surface
msh = mrViewGet(ui, 'CurMesh');
if isempty(msh), myErrorDlg('No Mesh Loaded.'); end

% get xform between the data and the I|P|R (mesh) coordinates
ii = cellfind( {ui.spaces.name}, 'I|P|R' );
xform = ui.spaces(ii).xform;

% get start coord (in base coordinate space)
varargin = unNestCell(varargin);
if isempty(varargin)   
	% xform cursor position into base space
	startCoord = mrmGet(msh, 'CursorPosition');
	startCoord = coordsXform(inv(xform), startCoord);
else
	startCoord = varargin{1};
end

% xform the segmentation's nodes/edges into the base coordinate space, too
seg = mrViewGet(ui, 'segmentation');
seg.nodes([2 1 3],:) = coordsXform( inv(xform), seg.nodes([2 1 3],:) )';
seg.nodes(1:3,:) = round(seg.nodes(1:3,:));

% get gray matter node corresponding to the start coord
startCoord = floor(startCoord);
startNode = find( seg.nodes(2,:)==startCoord(1) & ...
				  seg.nodes(1,:)==startCoord(2) & ...
				  seg.nodes(3,:)==startCoord(3) );
if isempty(startNode)
	myWarnDlg( sprintf('Node not found for start coordinate %s.', ...
					num2str(startCoord)) );
	return
end

%% get data mask based on overlays, thresholds
mask3D = mrViewGet(ui, 'OverlayMask');
sz = size(mask3D);

% index mask according to the nodes
mask = logical( zeros(1, size(seg.nodes, 2)) );
allNodes = seg.nodes;
keep = find( allNodes(1,:) > 0 & allNodes(2,:) < sz(1) & ...
			allNodes(2,:) > 0 & allNodes(1,:) < sz(2) & ...
			allNodes(3,:) > 0 & allNodes(3,:) < sz(3) );
allNodes = allNodes(:,keep);
I = sub2ind( size(mask3D), allNodes(1,:), allNodes(2,:), allNodes(3,:) );
mask(I) = mask3D(I);
% clear mask3D

% does the start node pass the criterion? If not, we shouldn't make an ROI
% with it:
if mask(startNode)==0
	myWarnDlg('The selected start point doesn''t pass the threshold.');
	return
end

%% initialize an empty ROI
roi = roiCreate(ui.mr);
roi.name = ['Mesh ROI ' num2str(startCoord)];
roi.comments = sprintf(['Created by %s ''Meshgrow'' grown from seed %s'], mfilename, ...
						num2str(startCoord));									
					
%% main part: "grow" coords in ROI (recursive)
h = msgbox('Growing Mesh ROI', mfilename);
iNodes = growMeshROICoords(startNode, seg, mask);
close(h);

roi.coords = coordsXform( inv(xform), seg.nodes([2 1 3],iNodes) );

%% add ROI to viewer
ui = mrViewSet(ui, 'AddAndSelectROI', roi);

return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function nodes = growMeshROICoords(nodes, seg, mask);
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
	nEdges = seg.nodes(4,n);
	startEdge = seg.nodes(5,n);
	neighbors = [neighbors seg.edges(startEdge:startEdge+nEdges-1)];
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
	nodes = growMeshROICoords([nodes neighbors], seg, mask);
end
	
return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewDiskROI(ui, varargin);
%%%%%Create Disk ROI
varargin = unNestCell(varargin);
if isempty(varargin)    % get disk size via dialog
	q = {'Size of Gray Matter Disk?'};
	resp = inputdlg(q, 'Make Disk ROI', 1, {'3'});
	radius = str2num(resp{1});
else
	radius = varargin{1};            
end

roi = roiGrayDisk(mrViewGet(ui, 'CurSegmentation'), ui.mr, radius);
ui = mrViewSet(ui, 'AddAndSelectROI', roi);
ui = mrViewRecenter(ui, 'roi');
try,   mrViewROI('draw', ui);   end
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = mrViewGrayROI(ui, varargin);
%%%%%Create Gray Matter ROI
seg = mrViewGet(ui, 'CurSegmentation');
roi = roiGrayAll(seg, ui.mr);
ui = mrViewSet(ui, 'newROI', roi);

try,   mrViewROI('draw', ui);   end

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function coords = roiRectCoords(ui);
% Get points from the user specifying a rectangle on the mrViewer display,
% and compute a 3xN list of coordinates which that input represents.
figure(ui.fig);
tmp = get(ui.panels.display,'BackgroundColor');
set(ui.panels.display,'BackgroundColor','y');
hmsg = mrMessage('Select Corners of Rectangle');
[X Y] = ginput(2);
X = round(X); Y = round(Y);
set(ui.panels.display,'BackgroundColor',tmp);
close(hmsg);

% figure out what image was clicked on
imgNum = find(ui.display.axes==gca);
if isempty(imgNum)
    warning('Didn''t click on mrViewer display. No points added.')
    coords = [];
    return
end


% get range of rows (Y) and columns (X) corresponding to rectangle
% (the corner of the image isn't always (0,0), because of
% diff't coordinate transforms. So, account for the viewed range.)
AX = axis;
rows = round([min(Y):max(Y)]); %  - AX(3) + 1
cols = round([min(X):max(X)]); %  - AX(1) + 1

% get coordinates (in base MR data) of selected points
imgCoords = mrViewGet(ui,'DataCoords',imgNum); % whole image
imgSz = size(ui.display.images{imgNum}); imgSz = imgSz(1:2);
I = reshape(1:prod(imgSz),imgSz); % index matrix

% get indices that correspond to the rectange, and return those coords
ind = I(rows,cols);
coords = imgCoords(:,ind(:));

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function coords = roiCircleCoords(ui);
% Get points from the user specifying a circle on the mrViewer display,
% and compute a 3xN list of coordinates which that input represents.
figure(ui.fig);
tmp = get(ui.panels.display,'BackgroundColor');
set(ui.panels.display,'BackgroundColor','y');
hmsg = mrMessage('Select center of circle, then a point on circumference');
AX = axis;
[X Y] = ginput(2);
X = round(X-AX(1)+1);
Y = round(Y-AX(3)+1);
close(hmsg);
set(ui.panels.display,'BackgroundColor',tmp);

% figure out what image was clicked on
imgNum = find(ui.display.axes==gca);
if isempty(imgNum)
    warning('Didn''t click on mrViewer display. No points added.')
    coords = [];
    return
end

% create a matrix R specifying the distance of each pixel in the
% image from the first selected point (center of circle):
imgSz = size(ui.display.images{imgNum});
[xx,yy] = meshgrid(1:imgSz(2),1:imgSz(1));
dX = xx-X(1); dY = yy-Y(1);
R = sqrt(dX.*dX + dY.*dY);

% the points in the circle are points where R is less than the
% radius (the distance between the first and second points):
radius = sqrt(diff(X)^2 + diff(Y)^2);
inCircle = find(R<radius);

% get coordinates (in base MR data) within the circle
allCoords = mrViewGet(ui,'DataCoords',imgNum); % whole image
coords = allCoords(:,inCircle);

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function coords = roiCubeCoords(ui);
% Get points from the user specifying a cube on the mrViewer display,
% and compute a 3xN list of coordinates which that input represents.
coords = [];
myWarnDlg('Sorry, Not Implemented Yet');
return
% /--------------------------------------------------------------------/ %


% /--------------------------------------------------------------------/ %
function coords = roiSphereCoords(ui);
% Get points from the user specifying the center, and a point on the surface, of a sphere
% in the mrViewer display, and compute a 3xN list of coordinates which that input represents.
figure(ui.fig);
tmp = get(ui.panels.display,'BackgroundColor');
set(ui.panels.display,'BackgroundColor','y');
hmsg = mrMessage('Select center of sphere, then a point on circumference');
AX = axis;
[X Y] = ginput(2);
X = round(X-AX(1)+1);
Y = round(Y-AX(3)+1);
close(hmsg);
set(ui.panels.display,'BackgroundColor',tmp);

% figure out what image was clicked on
imgNum = find(ui.display.axes==gca);
if isempty(imgNum)
    warning('Didn''t click on mrViewer display. No points added.')
    coords = [];
    return
end

% create a matrix R specifying the distance of each pixel in the
% image from the first selected point (center of sphere):
% TODO: xform grid to current view space
[xx yy zz] = meshgrid(1:ui.mr.dims(2), 1:ui.mr.dims(1), 1:ui.mr.dims(3));
dX = xx-X(1); dY = yy-Y(1);  dZ = zz-mrViewGet(ui, 'curslice');
R = sqrt(dX.*dX + dY.*dY + dZ.*dZ);

% the points in the circle are points where R is less than the
% radius (the distance between the first and second points):
radius = sqrt(diff(X)^2 + diff(Y)^2);
inSphere = find(R<radius);

% get coordinates (in base MR data) within the circle
% (This is a temp fix, will only work in pixel space)
coords = [yy(inSphere)'; xx(inSphere)'; zz(inSphere)'];

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function coords = roiLineCoords(ui);
% Get points from the user specifying a line on the mrViewer display,
% and compute a 3xN list of coordinates which that input represents.
figure(ui.fig);
tmp = get(ui.panels.display,'BackgroundColor');
set(ui.panels.display,'BackgroundColor','y');
hmsg = mrMessage('Select endpoints of line');
pts = round(ginput(2));
close(hmsg);
set(ui.panels.display,'BackgroundColor',tmp);

% figure out what image was clicked on
imgNum = find(ui.display.axes==gca);
if isempty(imgNum)
    warning('Didn''t click on mrViewer display. No points added.')
    coords = [];
    return
end

% find the 2D image coords that lie within the line specified by
% the two points
[cols rows] = findLinePoints(pts(1,:),pts(2,:));

% account for axis bounds
AX = axis;
cols = cols - AX(1) + 1;
rows = rows - AX(3) + 1;

% get coordinates (in base MR data) within the line
imgCoords = mrViewGet(ui,'DataCoords',imgNum); % whole image
imgSz = size(ui.display.images{imgNum}); imgSz=imgSz(1:2);
ind = sub2ind(imgSz,rows,cols);
coords = imgCoords(:,ind);

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function coords = roiPointCoords(ui);
% Get points from the user specifying individual points on the mrViewer
% display, and compute a 3xN list of coordinates which that input
% represents (in the base MR data).
figure(ui.fig);
tmp = get(ui.panels.display,'BackgroundColor');
set(ui.panels.display,'BackgroundColor','y');
hmsg = mrMessage('Left click to select point, right click to quit.');
X = []; Y = []; button = 1;
while button==1
    [newX newY button] = ginput(1);
    X = [X; newX]; Y = [Y; newY];
end
X = round(X); Y = round(Y);
close(hmsg);
set(ui.panels.display,'BackgroundColor',tmp);

% figure out what image was clicked on
imgNum = find(ui.display.axes==gca);
if isempty(imgNum)
    warning('Didn''t click on mrViewer display. No points added.')
    coords = [];
    return
end

% get coordinates (in base MR data) for the selected points
allCoords = mrViewGet(ui,'DataCoords',imgNum); % whole image
imgSz = size(ui.display.images{imgNum}); imgSz=imgSz(1:2);
ind = sub2ind(imgSz,Y,X);
coords = allCoords(:,ind);

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function coords = roiGrowCoords(ui);
% Get a point from the user from which to grow a 'blob' of
% interconnected points in 3D,  and return a 3xN list of coordinates
% for those points (in the base MR data).
figure(ui.fig);
tmp = get(ui.panels.display, 'BackgroundColor');
set(ui.panels.display, 'BackgroundColor', 'y');
hmsg = mrMessage('Select point from which to grow.');
pt = round(ginput(1));
close(hmsg);
set(ui.panels.display, 'BackgroundColor', tmp);

% figure out what image was clicked on
imgNum = find(ui.display.axes==gca);
if isempty(imgNum)
    warning('Didn''t click on mrViewer display. No points added.')
    coords = [];
    return
end

% find seed location in the data coords
% (take axis bounds into account)
imgCoords = mrViewGet(ui, 'DataCoords', imgNum);
imgSz = size(ui.display.images{imgNum}); imgSz=imgSz([1 2]);
AX = axis;
ind = sub2ind(imgSz, round(pt(2)-AX(3)+1), round(pt(1)-AX(1)+1));
% ind = sub2ind(imgSz, pt(2), pt(1));
seed = round(imgCoords(:,ind));

% First-pass method of growing a blob efficiently:
% (1) Create an initial box,  centered on seed
% (2) Restrict the box to coords which pass overlay thresholds
% (3) Find contiguous blob which contains seed
% (4) Test if box contains whole blob: if not,  repeat 1-4 iteratively
hmsg = msgbox('Growing ROI...');
boxSize = 10; stepSize = 10;
coords = [];
while 1
    % (1) create box (get coords specifying box in data)
    ymin = max(1, seed(1)-boxSize);
    ymax = min(ui.mr.dims(1), seed(1)+boxSize);
    xmin = max(1, seed(2)-boxSize);
    xmax = min(ui.mr.dims(2), seed(2)+boxSize);
    zmin = max(1, seed(3)-boxSize);
    zmax = min(ui.mr.dims(3), seed(3)+boxSize);
    [X Y Z] = meshgrid(xmin:xmax, ymin:ymax, zmin:zmax);
    boxCoords = [Y(:) X(:) Z(:)]'; clear X Y Z
    mask = logical(zeros(ui.mr.dims(1:3)));

    % (2) restrict box to overlays
    hidden = [ui.overlays.hide];
    boxCoords = mrViewRestrict(ui, boxCoords, find(~hidden));
    ok = sub2ind(size(mask), boxCoords(1,:), boxCoords(2,:), boxCoords(3,:));
    mask(round(ok)) = 1;

    % (3) Find contiguous blob which contains seed
    L = bwlabeln(mask,  6); % integer label matrix of 6-connected blobs
    seedLabel = L(seed(1), seed(2), seed(3));
    if seedLabel==0,  return;   end;  % no data so quit
    blob = (L==seedLabel); % binary matrix where blob is 1
    [i1,  i2,  i3] = ind2sub(size(mask), find(blob>0.5));
    coords = [i1 i2 i3]';

    % (4) Test if the box contains the entire blob
    % (Or is otherwise flush with the bounds of the data)
    inBoundsY=(all(i1>ymin)|ymin==1) & (all(i1<ymax)|ymax==ui.mr.dims(1));
    inBoundsX=(all(i2>xmin)|xmin==1) & (all(i2<xmax)|xmax==ui.mr.dims(2));
    inBoundsZ=(all(i3>zmin)|zmin==1) & (all(i3<zmax)|zmax==ui.mr.dims(3));
    if inBoundsX & inBoundsY & inBoundsZ
        break;
    else
        boxSize = boxSize + stepSize;
    end
end
close(hmsg);

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function ui = updateROIPopup(ui);
% update selected ROI popup if it exists
if checkfields(ui, 'controls', 'roiSelect') & ishandle(ui.controls.roiSelect)
    str = get(ui.controls.roiSelect, 'String');
    if isempty(ui.rois)
        str = {'(No ROIs)'};
    else
        str = {ui.rois.name};
	end
	val = max(1, ui.settings.roi); % if sel==0, select the '(No ROIs)' string
    set(ui.controls.roiSelect, 'String', str, 'Value', val);
end
return

