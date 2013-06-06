function vw = initHiddenGray(dataType,scan,roi);
%
% function hiddenGray = initHiddenGray([dataType],[scan],[roi])
%
% djh, sometime in 1999
% ras, 04/05, set name to 'hidden'
% ras, 05/05, added 'curScan' field
% ras, 09/05, ensures session is loaded, 
% mrGlobals is run; can specify data type,
% scan, and roi at outset.

%TODO: Decide if we want to add a 'loadAnat' to the initHiddenGray

if ~exist('dataType','var') || isempty(dataType)
    dataType = 1;
end

if ~exist('scan','var') || isempty(scan)
    scan = 1;
end

evalin('base','mrGlobals');
evalin('base','HOMEDIR = pwd;');
evalin('base','loadSession');

verbose = prefsVerboseCheck;
if verbose, disp('Initializing HIDDEN Gray view'); end

vw.name     ='hidden';
vw.viewType ='Gray';
vw.subdir   ='Gray';

% Initialize slots for anat co, amp, and ph
vw.anat         = [];
vw.co           = [];
vw.amp          = [];
vw.ph           = [];
vw.map          = [];
vw.mapName      = '';
vw.mapUnits     = '';
vw.tSeriesSlice = [];
vw.loc          = viewGet(vw,'Size') ./ 2;

% Initialize ROIs
vw.ROIs         = [];
vw.selectedROI  = 0;

% Initialize curDataType
if isnumeric(dataType),
    vw.curDataType = dataType;
elseif ischar(dataType),
    vw.curDataType = existDataType(dataType);
end

% Initialize curScan
vw.curScan = scan;

% need to record mmPerVox
vw.mmPerVox = readVolAnatHeader(getVAnatomyPath);

% Compute/load coords
vw = switch2Gray(vw);

% load any ROIs specified
if exist('roi','var') & ~isempty(roi)
    vw = loadROI(vw,roi);
end

% Dummy UI properties, allows loading of contrast maps on meshes w/o
% mrVista GUI open
vw = viewSet(vw, 'displaymode', 'anat');
vw = viewSet(vw, 'initdisplaymodes');

return