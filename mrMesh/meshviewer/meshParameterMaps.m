function [images mapVals] = meshParameterMaps(V, dialogFlag, varargin);
% Produce images of parameter maps on a mesh.
%
% NOTE: this will modify the 'map' field of the view.
%
% USAGE:
%   [images mapVals] = meshAmplitudeMaps(grayView, [dialogFlag], [options]);
%
% INPUTS:
%       grayView: mrVista gray view, with a mesh open. Will show maps on the
%       currently-selected mesh, if there are more than one. 
%
%		useDialog: 1 to put up a dialog to set the parameters, 0 otherwise.
%
%		options: options can be specified as 'optionName', [value], ...
%		pairs. Options are below:
%
%		mapFiles: name or path to parameter map file. [Default: use file
%		loaded for the map's current parameter map.]
%
%       plotFlag: flag to show the set of images returned in a montage. If 0,
%       will not plot; if 1 will plot. You can also specify a size for the
%       montage, as in plotFlag = [nRows, nCols]; otherwise the rows and
%       columns will be approximately square. 
%
%		nRows, nCols: alternate method for specifying the montage size
%		(rather than using the 'plotFlag' option described above). 
%
%       cropX, cropY: specify zoom ranges in the X and Y dimensions for each
%       mesh image. If omitted, will show the entire mesh.
%
%		whichScans: select the scans in the current data type for which to show
%		the map. [Default: view's current scan].
%
%		preserveCoords: flag to return mapVals with exactly the same number
%		of columns as the ROI coordinates. If this is set to 1, and certain
%		ROI coordinates don't have data, mapVals will have NaN for that
%		column. If 0 [default], these columns are automatically removed
%		from the matrix.
%
% OUTPUTS:
%       images: nRows x nCols cell array containing mesh images for each
%       condition in the GLM.
%
%		mapVals: conditions x voxels matrix containing the amplitude values
%		used in the map images for the selected ROI.
%
% ras, 03/2008.
if notDefined('V'),				V = getSelectedGray;					end
if notDefined('dialogFlag'),	dialogFlag = (length(varargin)<=1);		end

%% checks
% check that a mesh is loaded
if isempty( viewGet(V, 'curMesh') )
	error('Need to load a mesh.')
end

images = {};
mapVals = [];

%% params
% default params
preserveCoords = 0;
mapFiles = { fullfile(dataDir(V), [V.mapName '.mat']) };
mapOrder = [];
cmap = 'coolhot';
clim = [-2 2];
cropX = [];
cropY = [];
cmap = mrvColorMaps('coolhot', 128);
clim = [-2 2];
plotFlag = 1;
whichScans = V.curScan;
whichMeshes = 1:length(V.mesh);
maskRoi = '';
nRows = []; nCols = [];

% grab the current map mode (which contains the color map and
% color limits) -- we'll assume these settings are the ones you want to
% apply to each map (loadParameterMap below may over-ride these in the view,
% so we restore them later):
mapMode = V.ui.mapMode;
mapWin = getMapWindow(V);

% get params from dialog if needed
if dialogFlag==1
	[params ok] = meshParameterMapGUI(V);
	if ~ok, disp('User Aborted.'); return; end
	
	mapFiles = params.mapFiles;
	mapOrder = params.mapOrder;
	whichMeshes = params.whichMeshes;
	plotFlag = params.plotFlag;
	cropX = params.cropX;
	cropY = params.cropY;
	cmap = params.cmap;
	clim = params.clim;
	preserveCoords = params.preserveCoords;
	whichScans = params.whichScans;	
	if length(params.montageSize) >= 2
		nRows = params.montageSize(1);
		nCols = params.montageSize(2);
	else
		nRows = [];
		nCols = [];
	end
	maskRoi = params.maskRoi;
	if isequal(maskRoi, 'none')
		maskRoi = '';
	end
			
	if checkfields(V, 'ui', 'mapMode')
		V.ui.mapMode = mapMode;
	end
end

% set the map mode settings to reflect the request color map and limits
if ischar(cmap)
	mapMode.cmap = [gray(128); mrvColorMaps(cmap, 128)];
else
	mapMode.cmap = [gray(128); cmap];
end
mapMode.clipMode = clim;


% parse options (these will override the dialog values)
for ii = 1:2:length(varargin)
	val = varargin{ii+1};
	eval( sprintf('%s = val;', varargin{ii}) );
end

if ischar(mapFiles), mapFiles = {mapFiles}; end

if ischar(cmap)
	mapMode.cmap = [gray(128); mrvColorMaps(cmap, 128)];
else
	mapMode.cmap = [gray(128); cmap];
end
mapMode.clipMode = clim;


%% set the ROI mask, if requested
if length(V.ROIs) >= 1 & ~isempty(maskRoi);
	% we modify the view's ROIs here, but don't return the modified
	% view:
	oldROIs = V.ROIs;
	oldSelROI = V.selectedROI;

	roiNum = findROI(V, params.maskRoi);
	V.ROIs = V.ROIs(roiNum);
	V.ROIs.name = 'mask';
	V.selectedROI = 1;
end

nScans = length(whichScans);

%% if requesting the map values, mark which data nodes to take
if nargout > 1
	% I is the indices from which to extract values
	if isempty(maskRoi)
		% take all nodes
		I = 1:size(V.coords, 2);
	else
		I = roiIndices(V, V.ROIs(1).coords, preserveCoords);
	end
end

% compute the default # of rows/columns if it's left empty
if isempty(nRows) | isempty(nCols)
	nRows = ceil( sqrt(length(mapFiles)) );
	nCols = ceil( length(mapFiles) / nRows );
end

%% main loop: get pictures of each set of maps
% first, re-order the map files to the user's specification
if isempty(mapOrder), 
	mapOrder = 1:length(mapFiles);
end
mapFiles = mapFiles(mapOrder);

% now, get the values
for m = 1:length(mapFiles)
	% load the parameter map
	V = loadParameterMap(V, mapFiles{m});

	% get images for each scan
	for n = 1:length(whichScans)
		% set the scan
		V.curScan = whichScans(n);

		% set the color map and color limits
		% (the saved param map may have over-set this):
		V.ui.mapMode = mapMode;

		for h = 1:length(whichMeshes)
			% update the mesh
			V.meshNum3d = whichMeshes(h);
			meshColorOverlay(V);

			% grab the image
			img{h} = mrmGet(V.mesh{whichMeshes(h)}, 'screenshot') ./ 255;

			% crop the image if requested
			if ~isempty(cropX) & ~isempty(cropY)
				img{h} = img{h}(cropY,cropX,:);
			end
			
		end
		
		% add image to list of images
		% (make montage if taking a shot of multiple meshes)
		if length(whichMeshes)==1
			img = img{1};
		else
			img = imageMontage(img, 1, length(whichMeshes));
		end
		images{(m-1)*nScans + n} = img;
		clear img
		
		%% grab map values for the ROI if requested
		if nargout > 1
			% extract the values for the selected ROI
			mapVals((m-1)*nScans + n,:) = V.map{V.curScan}(I);
		end
	end
end

%% restore the ROIs if we were masking
if exist('oldROIs', 'var')
	V.ROIs = oldROIs;
	V.selectedROI = oldSelROI;
	updateGlobal(V);
	if checkfields(V, 'ui', 'windowHandle')
		refreshScreen(V);
	end
end

%% display the images if selected
if ~isequal(plotFlag, 0)
	% we'll manually specify subplot sizes -- large:
	width = 1 / nCols;
	height = 1 / nRows;

	% open the figure
	figure('Units', 'norm', 'Position', [0.2 0 .7 .35], 'Name', 'Mesh Images');

	% plot each mesh image in a subplot:
	% allow for some images to be omitted if the user specified
	% a montage size that is smaller than the # of images
	% (e.g., an extra 'scrambled' condition)
	for n = 1:min(length(images), nRows*nCols);
		row = ceil(n / nCols);
		col = mod(n-1, nCols) + 1;
		subplot('Position', [(col-1)*width, 1 - row*height, width, height]);
		imagesc(images{n}); axis image; axis off;
	end

	% add a colorbar
	if check4File(mapFiles{1})
		tmp = load(mapFiles{1});
		if isfield(tmp, 'mapUnits') & ~isempty(tmp.mapUnits)
			cbarTitle = sprintf('%s (%s)', tmp.mapName, tmp.mapUnits)
		else
			cbarTitle = tmp.mapName;			
		end
	else
		[par cbarTitle] = fileparts(mapFiles{1});
	end
	cmap = viewGet(V, 'OverlayColormap');
	clim = viewGet(V, 'MapClim');
	cbar = cbarCreate(cmap, cbarTitle, 'Clim', clim);

	hPanel = mrvPanel('below', .2);
	hAxes = axes('Parent', hPanel, 'Units', 'norm', 'Position', [.3 .5 .4 .2]);
	cbarDraw(cbar, hAxes);
end

return
% /----------------------------------------------------------------------/ %




% /----------------------------------------------------------------------/ %
function [params ok] = meshParameterMapGUI(V);
% dialog to get parameters for meshAmplitudeMaps.
dlg(1).fieldName = 'mapFiles';
dlg(end).style = 'listbox';
w = what(dataDir(V));
if isempty(w.mat)
	warning('No maps found in current data type: %s', getDataTypeName(V));
	ok = 0;
	params = [];
	return
end
dlg(end).list = w.mat;
if ~isempty( cellfind(V.map) ) & ~isempty(V.mapName)
	dlg(end).value = V.mapName;
else
	dlg(end).value = '';
end
dlg(end).string = 'Parameter map file(s)?';

dlg(end+1).fieldName = 'mapOrder';
dlg(end).style = 'number';
dlg(end).value = [];
dlg(end).string = 'Order of maps?';


dlg(end+1).fieldName = 'whichMeshes';
dlg(end).style = 'listbox';
for n = 1:length(V.mesh)
	meshList{n} = sprintf('%i: %s', V.mesh{n}.id, V.mesh{n}.name);
end
dlg(end).list = meshList;
dlg(end).value = V.meshNum3d;
dlg(end).string = 'Project data onto which meshes?';

dlg(end+1).fieldName = 'whichScans';
dlg(end).style = 'number';
dlg(end).value = V.curScan;
dlg(end).string = 'Plot data from which scans?';

dlg(end+1).fieldName = 'cropX';
dlg(end).style = 'number';
dlg(end).value = [];
dlg(end).string = 'Mesh X-axis image crop (empty for no crop)?';

dlg(end+1).fieldName = 'cropY';
dlg(end).style = 'number';
dlg(end).value = [];
dlg(end).string = 'Mesh Y-axis image crop (empty for no crop)?';

dlg(end+1).fieldName = 'montageSize';
dlg(end).style = 'number';
dlg(end).value = [];
dlg(end).string = 'Montage layout ([nrows ncolumns])?';

dlg(end+1).fieldName = 'cmap';
dlg(end).style = 'popup';
dlg(end).list = mrvColorMaps;  % list of available cmaps
dlg(end).value = 'coolhot';
dlg(end).string = 'Color map for amplitudes?';

if length(V.ROIs) >= 1
	dlg(end+1).fieldName = 'maskRoi';
	dlg(end).style = 'popup';
	dlg(end).list = [{'none'} {V.ROIs.name}]; 
	dlg(end).value = 'none';
	dlg(end).string = 'Mask activations within which ROI?';
end

dlg(end+1).fieldName = 'clim';
dlg(end).style = 'number';
dlg(end).value = [-2 2];
dlg(end).string = 'Color limits for amplitudes?';

dlg(end+1).fieldName = 'preserveCoords';
dlg(end).style = 'checkbox';
dlg(end).value = 0;
dlg(end).string = 'Preserve ROI coordinates in returned values?';

dlg(end+1).fieldName = 'plotFlag';
dlg(end).style = 'checkbox';
dlg(end).value = 1;
dlg(end).string = 'Plot Results?';

[params ok] = generalDialog(dlg, 'Mesh Parameter Maps');

[ignore, params.whichMeshes] = intersect(meshList, params.whichMeshes);

return