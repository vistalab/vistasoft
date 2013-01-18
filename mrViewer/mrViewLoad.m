function ui = mrViewLoad(ui, pth, type, format, varargin);
% Load a new MR data file / ROI / other data into a mrViewer UI.
%
%   ui = mrViewLoad([ui, pth, type, format, [options]]);
%
% ui: mrViewer UI struct. Finds the most current one if
% omitted.
%
% pth: path to the MR file/s to load. (see mrLoad.)
%
% type: flag for what type of data to load:
%       0 [default]: load the newMR object as the new 'base' newMR object
%                    (stored in the ui.newMR field); the spaces,
%                    as well as any overlays/ROIs/ will need to be
%                    redefined in terms of this new space.
%       1:          load as a map in the ui.maps cell array, to be used
%                   for overlays.
%       2:          load ROI.
%       3:          load space transformation information. Right now,
%                   this means loading a mrSESSION.alignment field. May
%                   become more general in the future.
%       4:          load stimulus files / parfiles.
%       5:          segmentation.
%       6:          mesh.
%       7:          mesh settings file.
% type can also be a string out of:
%   'base', 'map', 'roi', 'space', 'stim', 'segmentation', 'mesh'.
%   'meshsettings'.
%
% format: file format (see mrLoad). Usually, this can be omitted
% and will be inferred from the filename.
%
% For some data types, the code will accept optional additional arguments.
% For instance, when loading a map, the 5th argument can specify which
% sub-volume to load in a map. (E.g., if a map comprises multiple 3-D
% scans, the argument can specify which of these scans to keep, discarding
% the others.)
%
% ras 07/05.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet;            end
if ishandle(ui),                     ui = get(ui,'UserData');   end
if ~exist('type','var') | isempty(type), type = 0;     end
if ~exist('pth', 'var'),		pth = '';						end
if ~exist('format', 'var'),		format = '';					end

typesList = {'base', 'map', 'roi', 'space', 'stim', 'segmentation', ...
	'mesh' 'meshsettings'};

if isnumeric(type), 	type = typesList{type+1};			end

if ~ismember(lower(type), typesList), error('Invalid data type.'); end


% ras 03/07: converted SWITCH statement into a set of sub-functions, to
% make 'em easier to get to.
subfun = sprintf('mrViewLoad%s%s', upper(type(1)), lower(type(2:end)));
if isempty(varargin)
	% evaluate the sub-function without additional options
	ui = feval(subfun, ui, pth, format);
else
	% also pass along the options
	ui = feval(subfun, ui, pth, format, varargin);
end

% update the UI figure
if ishandle(ui.fig)
	set(ui.fig,'UserData',ui);
end

return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function ui = mrViewLoadBase(ui, pth, format, varargin);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load as a base object:
% adjust spaces accordingly. When overlays
% and ROIs are added, will need to adjust these as
% well.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if notDefined('pth')
	ui.mr = mrLoad;
elseif notDefined('format')
	ui.mr = mrParse(pth); % also allow struct
else
	ui.mr = mrLoad(pth, format);
end
ui.spaces = ui.mr.spaces;

return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function ui = mrViewLoadMap(ui, pth, format, varargin);
%%%%%%%%%%%%%%%%%
% load as a map %
%%%%%%%%%%%%%%%%%
if notDefined('pth')
	pth = mrLoad;
elseif ~exist(pth, 'file')
	% check: if the path is a string to a file that can't be
	% found, see if it's relative to a mrVista data directory:
	if ischar(pth) | ~exist(pth, 'file')
		mrGlobals2;
		test = fullfile(dataDir(INPLANE{1}), [pth '.mat']);
		if exist(test, 'file'), pth = test; end
	end
end

if notDefined('format')
	newMR = mrParse(pth);
else
	newMR = mrLoad(pth, format);
end

%%%%%special case: old corAnal files
if isequal(newMR.name,'Coherence') & isequal(newMR.format,'1.0corAnal')
	[co amp ph] = mrReadOldCorAnal(newMR.path);
	ui = mrViewAddMap(ui,co);
	ui = mrViewAddMap(ui,amp);
	ui = mrViewAddMap(ui,ph);
	return
end

% varargin may specify a set of scans from which to take the map
if ~isempty(varargin)
	varargin = unNestCell(varargin);
	scans = varargin{1};
	try
		% find the indices I which correspond to the requested scans
		[scansWithData, I] = intersect(newMR.info.scans, scans);
		if length(scansWithData) < length(scans)
			% can't load all the specified scans? error.
% 			error('Can''t load all selected scans.')
		end
		
		% sub-select the scan data
		newMR.data = newMR.data(:,:,:,I);
		newMR.dims = size(newMR.data);
		newMR.info.scans = newMR.info.scans(I);
		if prefsVerboseCheck >= 1
			fprintf('[%s]: Loading map data from scans %s.\n', ...
					mfilename, num2str(scans));
		end		
	catch
		if prefsVerboseCheck >= 1
			fprintf('[%s]: Couldn''t sub-select scans; loading all scans.\n', ...
					mfilename);
		end
	end
end

% finally, add the new MR data as a map to the UI:
ui = mrViewAddMap(ui, newMR);

return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function ui = mrViewLoadRoi(ui, pth, format, varargin);
%%%%%%%%%%%%
% Load ROI %
%%%%%%%%%%%%
if ~iscell(pth), pth = {pth}; end

for i = 1:length(pth)
	% check: if the path is a string to a file that can't be
	% found, see if it's relative to a mrVista ROI directory:
	if ~check4File(pth{i}, '.mat')
		mrGlobals2;
		test = fullfile(roiDir(INPLANE{1}), [pth{i} '.mat']);
		if exist(test, 'file'), pth{i} = test; end
	end			

	if ~check4File(pth{i}, '.mat')
		% still not found? Don't crash, just warn about it.
		warning( sprintf('%s not found.', pth{i}) );
		return
	end

	roi = roiCheckCoords(pth{i}, ui.mr);  % this will load the ROI file
	roi.lineHandles = []; % for drawing ROIs
	roi.prevCoords = []; % for undo
	if isequal(ui.mr.name, 'Inplane')
		roi.viewType = 'Inplane';
		roi.reference = ui.mr.path;
		roi.voxelSize = ui.mr.voxelSize;
	else
		roi.viewType = 'Volume';
		roi.reference = getVAnatomyPath;
		hdr = mrLoadHeader(roi.reference);
		roi.voxelSize = hdr.voxelSize;
	end

	ui = mrViewSet(ui, 'AddROI', roi);
end

return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function ui = mrViewLoadSpace(ui, pth, format, varargin);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Space Transformation / Alignment %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isequal(lower(pth), 'dialog')
	% get path with a dialog
	txt = 'Select a mrSESSSION.mat file with the desired alignment';
	pth = mrSelectDataFile('stayput', 'r', '*.mat', txt);
end

[p f ext] = fileparts(pth);
if ~isequal(lower(f), 'mrsession')
	error('Can only load a mrSESSION alignment right now.');
end
load(pth, 'mrSESSION');

% create the new space -- this only works if the base MR object
% is the vAnatomy to which the inplanes were aligned:
ip = mrSESSION.inplanes;
ui.spaces(end+1).name = sprintf('%s Inplanes', mrSESSION.sessionCode);
ui.spaces(end).xform = inv(mrSESSION.alignment);
try
	ifileDir = fullfile(p, 'Raw', 'Anatomy', 'Inplane');
	w = dir(fullfile(ifileDir, 'I*'));
	ifile = fullfile(ifileDir, w(1).name);
	ui.spaces(end).dirLabels = mrIfileDirections(ifile);
catch
	ui.spaces(end).dirLabels = {'Rows' 'Cols' 'Slices'};
end
ui.spaces(end).sliceLabels = {'Rows' 'Cols' 'Slices'};
ui.spaces(end).units = 'Inplane Voxels';
ui.spaces(end).bounds = [1 1 1; ip.cropSize ip.nSlices]';

% add an option for this space in the 'Coordinates' menu
N = length(ui.spaces);
cb = sprintf('mrViewSet([],''Space'',%i); mrViewRefresh;', N);
h = uimenu(ui.menus.space, 'Label',ui.spaces(N).name, ...
	'Checked','off', 'Callback',cb);
ui.spaces(N).menuHandle = h;

return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function ui = mrViewLoadStim(ui, pth, format, varargin);
ui = mrViewAttachStim(ui, pth);
return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function ui = mrViewLoadSegmentation(ui, pth, format, varargin);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Segmentation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(pth) & exist(pth, 'file')
	%% load from a saved segmentation file...
	load(pth, 'seg');
	saveFlag = 0;

else
	%% create a segmentation, based on .class and .gray files
	saveFlag = 1; % will offer to save this info below...
	classFilters = {'*lass' 'mrGray Classification File'; ...
					'*nii*' 'NIFTI-format Classification File'; ...
					'*.*' 'All Files'};
	grayFilters = {'*ray' 'mrGray Gray Graph'; ...
				   '*.*' 'All Files'};
	classPath = mrvSelectFile('r', classFilters, 'Select Class File');
	grayPath = mrvSelectFile('r', grayFilters, 'Select Gray Graph');
	[ignore def] = fileparts(fileparts(classPath));
	name = inputdlg('Name of Segmentation?', mfilename, 1, {def});
	if isempty(name), return; else, name = name{1}; end
	seg = segCreate(name, classPath, grayPath);
end

ui = mrViewSet(ui, 'AddSegmentation', seg);

if saveFlag==1
	resp = questdlg(['Do you want to save a small segmentation ' ...
		'file, remembering the paths and name you ' ...
		'selected?'], 'Yes', 'No');
	if isequal(resp, 'Yes')
		seg = ui.segmentation(end);
		segPath = fullfile(fileparts(seg.class), 'segmentation.mat');
		save(segPath, 'seg');
		fprintf('Saved segmentation info in %s.\n', segPath);
	end
end


return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function ui = mrViewLoadMesh(ui, pth, format, varargin);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Mesh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isfield(ui.settings, 'segmentation') | ~isfield(ui, 'segmentation')
	resp = questdlg('No Segmentation installed. Install one now?');
	if isequal(resp, 'Yes')
		ui = mrViewLoad(ui, [], 'segmentation')
	else
		disp('mrViewLoad mesh aborted.'); return
	end
end

s = ui.settings.segmentation;
if isequal(lower(pth), 'firstmesh')
	% special: take the first mesh in the mesh dir
	startDir = ui.segmentation(s).params.meshDir;
	w = what(startDir);
	w.mat = setdiff(w.mat, {'MeshAngles.mat' 'MeshSettings.mat'});
	if isempty(w.mat)
		error( sprintf('No meshes found in %s.', startDir) );
	end
	pth = fullfile(startDir, w.mat{1});
elseif ~exist('pth', 'var') | ~exist(pth, 'file')
	startDir = ui.segmentation(s).params.meshDir;
	pth = mrvSelectFile('r', 'mat', 'Select Mesh File', startDir);
end
if ~exist(pth, 'file'), return; end % user canceled

ui = mrViewAddMesh(ui, mrmReadMeshFile(pth));

return
% /-----------------------------------------------------------------/ %



% /-----------------------------------------------------------------/ %
function ui = mrViewLoadMeshsettings(ui, pth, format, varargin);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Mesh Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if notDefined('pth')      % pth is mesh dir in this case
	pth = mrViewGet(ui, 'CurMeshDir');
	if ~exist(pth, 'dir')
		[f pth] = uigetfile('*.mat', 'Select a Mesh Settings File');
	end
end

settingsFile = fullfile(pth, 'MeshSettings.mat');
if exist(settingsFile, 'file')
	load(settingsFile, 'settings');
	names = {settings.name};
	settingsList = findobj('Parent', ui.panels.mesh, 'Style', 'listbox');
	
	% check that the selected setting is within the range of the new set of
	% settings names
	n = get(settingsList, 'Value');
	if n > length(names), n = length(names); end
	
	set(settingsList, 'String', names, 'Value', n);
else
	warning( sprintf('Couldn''t find mesh settings file %s.', settingsFile) );
end
return

