function vw = initHiddenInplane(dataType,scan,roi)
% Initialize a (hidden) inplane view - do not open the GUI window
%
%   hiddenInplane = initHiddenInplane([dataType,scan,roi])
% 
% Used frequently when scripting. If any of the optional args are
% specified, the hidden view will have that data type and scan selected,
% and that ROI loaded. data types can be specified as names or numeric
% indices; ROIs can be specified as names or cells of names.
%
% djh, sometime in 1999
% ras, made name of hidden inplanes "hidden",
% this seems useful -- 04/05
% ras, 05/05, added curScan field
% ras, 06/05, ensures session is loaded, 
% mrGlobals is run; can specify data type,
% scan, and roi at outset.
% ras, 02/06: disabled the notice that this was being initialized.
% I've found it a bit distracting; just a preference...

if ~exist('dataType','var') || isempty(dataType)
    dataType = 1;
end

if ~exist('scan','var') || isempty(scan)
    scan = 1;
end

verbose = prefsVerboseCheck;
if verbose, disp('Initializing HIDDEN Inplane view'); end

evalin('base','mrGlobals');
evalin('base','HOMEDIR = pwd;');
evalin('base','loadSession');

%Initialize the view
vw = struct();
%TODO: Make all of the below use viewSets
vw = viewSet(vw,'name','hidden');
vw = viewSet(vw,'viewType','Inplane');
vw = viewSet(vw,'subdir','Inplane');

% Initialize slots for co, amp, and ph
vw = viewSet(vw,'co',[]);
vw = viewSet(vw,'amp',[]);
vw = viewSet(vw,'ph',[]);
vw = viewSet(vw,'map',[]);
vw = viewSet(vw,'mapName','');
vw = viewSet(vw,'mapUnits','');

% Initialize slots for tSeries
vw.tSeries      = [];
vw.tSeriesScan  = NaN;
vw.tSeriesSlice = NaN;

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

% Load Anatomy of this view
vw = loadAnat(vw);

% load any ROIs specified

if exist('roi','var') && ~isempty(roi)
    try
        vw = loadROI(vw,roi);
    catch
        fprintf('Couldn''t load ROI(s): \n')
        disp(roi)
    end

end

return
