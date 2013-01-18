function view = initHiddenVolume(dataType,scan,roi)
%
% function hiddenVolume = initHiddenVolume(dataType],[scan],[roi])
%
% djh, sometime in 1999
% ras, 04/05, set name to 'hidden'
% ras, 05/05, added 'curScan' field
if ~exist('dataType','var') | isempty(dataType)
    dataType = 1;
end

if ~exist('scan','var') | isempty(scan)
    scan = 1;
end

evalin('base','mrGlobals');
evalin('base','loadSession');
evalin('base','HOMEDIR = pwd;');

verbose = prefsVerboseCheck;
if verbose, disp('Initializing HIDDEN Volume view'); end

view.name='hidden';
view.viewType='Volume';
view.subdir='Volume';

% Initialize slots for anat, co, amp, and ph
view.anat = [];
view.co = [];
view.amp = [];
view.ph = [];
view.map = [];
view.mapName = '';
view.mapUnits = '';

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

% need to record mmPerVox
view.mmPerVox = readVolAnatHeader(getVAnatomyPath);

% Compute/load coords
view=switch2Vol(view);

return
