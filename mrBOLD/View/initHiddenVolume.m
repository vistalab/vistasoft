function vw = initHiddenVolume(dataType,scan,varargin)
%
% function hiddenVolume = initHiddenVolume(dataType],[scan],[varargin])
%
% djh, sometime in 1999
% ras, 04/05, set name to 'hidden'
% ras, 05/05, added 'curScan' field
if ~exist('dataType','var') || isempty(dataType)
    dataType = 1;
end

if ~exist('scan','var') || isempty(scan)
    scan = 1;
end

evalin('base','mrGlobals');
evalin('base','loadSession');
evalin('base','HOMEDIR = pwd;');

verbose = prefsVerboseCheck;
if verbose, disp('Initializing HIDDEN Volume view'); end

vw.name = 'hidden'; 
vw = viewSet(vw, 'viewType', 'Volume');
vw = viewSet(vw, 'subdir', 'Volume');

% Initialize slots for anat, co, amp, and ph
vw = viewSet(vw, 'co', []);
vw = viewSet(vw, 'amp', []);
vw = viewSet(vw, 'ph', []);
vw = viewSet(vw, 'map', []);
vw = viewSet(vw, 'mapName', '');
vw = viewSet(vw, 'mapUnits', '');

% Initialize ROIs
vw = viewSet(vw, 'ROIs', []);
vw = viewSet(vw, 'selected ROI', 0);


% Initialize curDataType
vw = viewSet(vw, 'current DataType', dataType);

% Initialize curScan
vw = viewSet(vw, 'current scan', scan);

% need to record mmPerVox
vw = viewSet(vw, 'mm per vox', readVolAnatHeader(getVAnatomyPath));

% Compute/load coords
vw=switch2Vol(vw);

return
