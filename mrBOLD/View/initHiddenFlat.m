function view = initHiddenFlat(subdir, dataType, scan, roi)
%
%  hiddenFlat = initHiddenFlat([subdir], [dataType, scan, roi])
%
% subdir: string specifying the flat subdirectory
%
% dataType: name or index # of selected data type (defaults to 'Original')
%
% scan: selected scan. [defaults to 1]
%
% roi: ROIs to load -- can be the name of an ROI file, or cell array of
% names. [default: don't load any ROIs.]
% 
% djh, sometime in 1999
% ras, 04/05, set name to 'hidden'
% ras, 05/05, added curScan field
% ras, 01/10, added data type, scan, roi args to bring it in line with
% initHiddenInplane/Gray code; evaluates mrGlobals and loadSession to make
% sure we're in the right session; makes dummy fields for UI data, so code
% like publishFigure works.
if ~exist('dataType','var') | isempty(dataType)
    dataType = 1;
end

if ~exist('scan','var') | isempty(scan)
    scan = 1;
end

disp('Initializing HIDDEN Flat view')

evalin('base','mrGlobals');
evalin('base','HOMEDIR = pwd;');
evalin('base','loadSession');

% Set viewType
view.name='hidden';
view.viewType='Flat';

% Prompt user for flat subdirectory
if ~exist('subdir','var')
    subdir = getFlatSubdir;
end
view.subdir = subdir;

% Initialize slots for co, amp, and ph
view.co = [];
view.amp = [];
view.ph = [];
view.map = [];
view.mapName = '';
view.mapUnits = '';

% Initialize slots for tSeries
view.tSeries = [];
view.tSeriesScan = NaN;
view.tSeriesSlice = NaN;

% Initialize ROIs
view.ROIs = [];
view.selectedROI = 0;

% Initialize curDataType
if isnumeric(dataType),
    view.curDataType = dataType;
elseif ischar(dataType),
    view.curDataType = existDataType(dataType);
end

% Initialize curScan
view.curScan = scan;

% Compute/load coords
view = getFlatCoords(view);

% load the anatomy
view = loadAnat(view);

% set up UI fields, which allow us to perform most of the visualization
% code (such as publishFigure) on this hidden view as we could with a
% non-hidden view. If we don't do these steps, a lot of functions won't
% work on the hidden view.
if exist( fullfile(viewDir(view), 'userPrefs.mat'), 'file' )
	view = loadPrefs(view);
	
	% one caveat: the saved preferences may specify a data type and scan
	% other than the one the user provided to this function. If so, go with
	% the one the user input.
	view.curScan = scan;
	if isnumeric(dataType),
		view.curDataType = dataType;
	elseif ischar(dataType),
		view.curDataType = existDataType(dataType);
	end
else
	if prefsVerboseCheck >= 1
		fprintf('[%s]: No user prefs found for %s.', mfilename, pwd);
	end
	view.ui.showROIs = -2; % show all ROIs by default
end
view.ui.imSize = [size(view.anat, 1) size(view.anat, 2)];	
view = makeFlatMask(view);

% load any ROIs specified
if exist('roi','var') & ~isempty(roi)
    view = loadROI(view,roi);
end


return;
