function [images, mapVals] = meshAmplitudeMaps(V, dialogFlag, varargin);
% Produce images of response amplitudes (estimated one of a number of
% different ways) for different event-related conditions on a mesh.
%
% NOTE: this will modify the 'map' field of the view.
%
% USAGE:
%   [images mapVals] = meshAmplitudeMaps(grayView, [dialogFlag], [options]);
%
% INPUTS:
%       grayView: mrVista gray view, with a mesh open. Will show maps on the
%       currently-selected mesh, if there are more than one. The gray view
%       should have a 'GLMs' data type, and be pointed at the appropriate GLM
%       from which to load amplitude information.
%
%		useDialog: 1 to put up a dialog to set the parameters, 0 otherwise.
%
%		options: options can be specified as 'optionName', [value], ...
%		pairs. Options are below:
%
%       ampType: one of 'z-score', 'subtracted-betas', or 'raw-betas'; a ampType
%       for determining the amplitude of each voxel to each stimulus. The
%       methods are as follows:
%               'raw-betas': raw beta coefficients from the GLM. Each value
%               represents the estimated response of that voxel to the stimulus
%               compared to the baseline condition.
%
%               'subtracted-betas': beta coefficients minus the "cocktail blank,"
%               which is the mean beta value for that voxel, across all conditions.
%
%               'z-score': the subtracted-beta value, divided by the estimated
%               standard devation for the model fitting. The standard deviation is
%               defined as
%                       sqrt( residual ^2 / [degrees of freedom] )
%               and reflects the goodness-of-fit of the GLM as a whole. This causes
%               voxels with a poor GLM fit to have amplitudes closer to zero.
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
%		whichConds: select only a subset of conditions to analyze. [By
%		default, will present all conditions]. For the normalization
%		amplitude types (subtracted-betas and z-scores), the choice of which
%		conditions to include affects how the normalization is carried out.
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
msh = viewGet(V, 'CurMesh');

if isempty(msh)
	error('Need to load a mesh.')
end

% check that a GLM has been run
if ~isequal(viewGet(V, 'DTName'), 'GLMs')
	error('Need to be in the GLMs data type.')
end

% get scan num, # of non-null conditions
scan = viewGet(V, 'CurScan');
stim = er_concatParfiles(V);
N = length(stim.condNames) - 1;  % omit baseline condition

%% params
% default params
preserveCoords = 0;
ampType = 'z-score';
whichMeshes = V.meshNum3d;
cropX = [1:512];
cropY = [1:512];
cmap = mrvColorMaps('coolhot', 128);
clim = [-2 2];
saveAmps = 0;
plotFlag = 1;
titleFlag = 1;


% figure out # of rows, cols for the image montage
if length(plotFlag) > 1
	nRows = plotFlag(1);
	nCols = plotFlag(2);
else
	nRows = ceil( sqrt(N) );
	nCols = ceil( N/nRows );
end

% grab the current map mode (which contains the color map and
% color limits) -- we'll assume these settings are the ones you want to
% apply to each map (loadParameterMap below may over-ride these in the view,
% so we restore them later):
mapMode = V.ui.mapMode;
mapWin = getMapWindow(V);

% get params from dialog if needed
if dialogFlag==1
	[params ok] = meshAmplitudeMapGUI(V);
	if ~ok, disp('User aborted'); return; end

	ampType = params.ampType;
	plotFlag = params.plotFlag;
	titleFlag = params.titleFlag;
	cropX = params.cropX;
	if isempty(cropX), cropX = [1:512]; end
	cropY = params.cropY;
	if isempty(cropY), cropY = [1:512]; end
	preserveCoords = params.preserveCoords;
	whichConds = params.whichConds;
	whichMeshes = params.whichMeshes;
	cmap = params.cmap;
	clim = params.clim;
	nRows = params.montageSize(1);
	nCols = params.montageSize(2);
	saveAmps = params.saveAmps;
		
	if length(V.ROIs) >= 1 & ~isequal(params.maskRoi, 'none')
		% we modify the view's ROIs here, but don't return the modified
		% view:
		oldROIs = V.ROIs;
		oldSelROI = V.selectedROI;
		
		roiNum = findROI(V, params.maskRoi);
		V.ROIs = V.ROIs(roiNum);
		V.ROIs.name = 'mask';
		V.selectedROI = 1;
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


%% if the beta maps haven't been xformed from inplanes, do it now
testFile = fullfile( dataDir(V), sprintf('betas-predictor%i.mat', N) );
if ~exist(testFile, 'file')
	hI = initHiddenInplane('GLMs', 1);

	for i = 1:N     % loop across conditions
		mapPath = fullfile(dataDir(hI), 'RawMaps', ...
			sprintf('betas_predictor%i.mat', i));
		hI = loadParameterMap(hI, mapPath);
		V = ip2volParMap(hI, V, 0, 1, 'linear'); % trilinear interpolation

		mapPath = fullfile(dataDir(hI), 'RawMaps', ...
			sprintf('stdDev_predictor%i.mat', i));
		hI = loadParameterMap(hI, mapPath);
		V = ip2volParMap(hI, V, 0, 1, 'linear');
	end

	hI = loadParameterMap(hI, 'Residual Variance.mat');
	V = ip2volParMap(hI, V, 0, 1, 'linear');
end

if notDefined('whichConds'),
	whichConds=1:1:N;
else
	N=length(whichConds);
end

%% get the amplitude estimate for each voxel
switch lower(ampType)
	case 'subtracted-betas'
		for i = 1:N
			n=whichConds(i);
			mapName = sprintf('betas-predictor%i', n);
			V = loadParameterMap(V, mapName);
			mapVals(i,:) = V.map{scan};
		end

		% remove the "cocktail blank" or mean of all conditions for each voxel
		mapVals = mapVals - repmat( nanmean(mapVals), [N 1] );

	case {'raw-betas' 'rawbetas' 'raw betas'}
		for i = 1:N
			n=whichConds(i);
			mapName = sprintf('betas-predictor%i', n);
			V = loadParameterMap(V, mapName);

			mapVals(i,:) = V.map{scan};
		end

	case {'z-score' 'z score' 'zscore'}
		% load the betas
		for i = 1:N
			n=whichConds(i);
			mapName = sprintf('betas-predictor%i', n);
			V = loadParameterMap(V, mapName);
			mapVals(i,:) = V.map{scan};
		end

		% load the residual variance map
		V = loadParameterMap(V, 'Residual Variance');
		sigmaVals = V.map{scan};

		% convert from res. var -> std. dev
		% (we need some info from the GLM model: degrees of freedom)
		modelFile = sprintf('Inplane/GLMs/Scan%i/glmSlice1.mat', scan);
		load(modelFile, 'dof');
		sigmaVals = sqrt( sigmaVals .^ 2 ./ dof );

		% remove the "cocktail blank" or DC component for each voxel
		mapVals = mapVals - repmat( nanmean(mapVals), [N 1] );

		% now, normalize by dividing by the estimated residual variance at
		% each voxel
		mapVals = mapVals ./ repmat( sigmaVals, [N 1] );

	otherwise
		error('Invalid amplitude type.')
end



%% main loop -- get the images
for n = 1:N
	% for convenient storage, know what category/position this is:
	% (we fill the conditions in row-major order: march across columns)
	row = ceil(n / nCols);
	col = mod(n-1, nCols) + 1;

	% set the map values
	V.map = cell(1, numScans(V));
	V.map{scan} = mapVals(n,:);

	% set the color map and color limits
	% (the saved param map may have over-set this):
	V.ui.mapMode = mapMode;
	V = setMapWindow(V, mrvMinmax(V.map{scan}));

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
		images{row, col} = img{1};
	else
		images{row, col} = imageMontage(img, 1, length(whichMeshes));
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
	% we'll want the event-related info for the condition names
	trials = er_concatParfiles(V);
	
	% we'll manually specify subplot sizes -- large:
	if titleFlag==1
		% we'll want to space out the axes to allow space for the condition
		% labels
		width = (1 / nCols) * 0.8;
		height = (1 / nRows) * 0.8;
	else
		% the images will be flush against one another
		width = 1 / nCols;
		height = 1 / nRows;
	end
	% open the figure
	figure('Units', 'norm', 'Position', [0.2 0 .7 .35], 'Name', 'Mesh Images');

	% plot each mesh image in a subplot:
	% allow for some images to be omitted if the user specified
	% a montage size that is smaller than the # of images
	% (e.g., an extra 'scrambled' condition)
	for n = 1:nRows*nCols
		row = ceil(n / nCols);
		col = mod(n-1, nCols) + 1;
		subplot('Position', [(col-1)*width, 1 - row*height, width, height]);
		imagesc(images{row,col}); axis image; axis off;
		
		if titleFlag==1
			cond = whichConds(n) + 1; % +1 for baseline condition name
			title(trials.condNames{cond});
		end
	end

	% add a colorbar
	cmap = viewGet(V, 'OverlayColormap');
	clim = viewGet(V, 'MapClim');
	cbar = cbarCreate(cmap, ampType, 'Clim', clim);

	hPanel = mrvPanel('below', .2);
	hAxes = axes('Parent', hPanel, 'Units', 'norm', 'Position', [.3 .5 .4 .2]);
	cbarDraw(cbar, hAxes);
end

%% export the amplitudes to a series of parameter maps if requested
if saveAmps==1
	for n = 1:N
		map = cell(1, numScans(V));
		map{scan} = mapVals(n,:);
		mapUnits = ampType;
		mapUnits(1) = upper(mapUnits(1));
		mapName = sprintf('%s Condition %i', mapUnits, whichConds(n));
		mapPath = fullfile(dataDir(V), [mapName '.mat']);
			
		save(mapPath, 'map', 'mapName', 'mapUnits');
		if prefsVerboseCheck >= 1
			fprintf('Exported amplitudes to map %s.\n', mapPath);
		end
	end
end

%% return map values for the ROI if requested
if nargout > 1
	if isempty(V.ROIs)
		I = 1:size(mapVals, 2);
	else
		I = roiIndices(V, V.ROIs(end).coords, preserveCoords);
	end
	mapVals = mapVals(:,I);
end

return
% /----------------------------------------------------------------------/ %




% /----------------------------------------------------------------------/ %
function [params ok] = meshAmplitudeMapGUI(V);
% dialog to get parameters for meshAmplitudeMaps.
stim = er_concatParfiles(V);

dlg(1).fieldName = 'ampType';
dlg(end).style = 'popup';
dlg(end).list = {'z-score' 'subtracted-betas' 'raw-betas'};
dlg(end).value = 1;
dlg(end).string = 'Plot what type of amplitude metric?';

dlg(end+1).fieldName = 'whichConds';
dlg(end).style = 'number';
dlg(end).value = 1:length(stim.condNums)-1;
dlg(end).string = 'Plot which conditions?';

dlg(end+1).fieldName = 'whichMeshes';
dlg(end).style = 'listbox';
for n = 1:length(V.mesh)
	meshList{n} = sprintf('%i: %s', V.mesh{n}.id, V.mesh{n}.name);
end
dlg(end).list = meshList;
dlg(end).value = V.meshNum3d;
dlg(end).string = 'Project data onto which meshes?';

dlg(end+1).fieldName = 'cropX';
dlg(end).style = 'number';
dlg(end).value = [];
dlg(end).string = 'Mesh X-axis image crop (empty for no crop)?';

dlg(end+1).fieldName = 'cropY';
dlg(end).style = 'number';
dlg(end).value = [];
dlg(end).string = 'Mesh Y-axis image crop (empty for no crop)?';

nConds = length(stim.condNums) - 1;
nRows = ceil( sqrt(nConds) );
nCols = ceil( nConds/nRows );
dlg(end+1).fieldName = 'montageSize';
dlg(end).style = 'number';
dlg(end).value = [nRows nCols];
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

dlg(end+1).fieldName = 'saveAmps';
dlg(end).style = 'checkbox';
dlg(end).value = 0;
dlg(end).string = 'Save amplitudes as a set of parameter maps?';

dlg(end+1).fieldName = 'plotFlag';
dlg(end).style = 'checkbox';
dlg(end).value = 1;
dlg(end).string = 'Plot Results?';

dlg(end+1).fieldName = 'titleFlag';
dlg(end).style = 'checkbox';
dlg(end).value = 1;
dlg(end).string = 'If plotting results, show condition names?';


[params ok] = generalDialog(dlg, 'Mesh Amplitude Maps');


[ignore, params.whichMeshes] = intersect(meshList, params.whichMeshes);

return


