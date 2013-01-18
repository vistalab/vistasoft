function view = importCorAnal(view, srcSession, srcDt, srcScan, tgtScan)
% Import corAnal fields from another session into the selected
% data type / scan for the current session. Only works for Volume / Gray
% views, and for sessions which share a common volume anatomy.
%
% view = importCorAnal(<view>, <srcSession, srcDt, srcScan>);
% 
% If any of the latter three arguments are omitted, pops up a dialog.
% srcSession: path to session directory from which to import.
% srcDt: name of data type (or index #) to import
% srcScan: scan from cor anal fields to take.
%
% ras, 01/06.
if notDefined('view'),    view = getSelectedGray;       end

if notDefined('tgtScan'), tgtScan = view.curScan;       end

if ~ismember(view.viewType, {'Volume' 'Gray'})
    error('Sorry, only Volume/Gray Views for now.')
end

mrGlobals;

if notDefined('srcSession')
    studyDir = fileparts(HOMEDIR);
    srcSession = selectSessions(studyDir,1);
    srcSession = srcSession{1};
end

% load source mrSESSION file
src = load(fullfile(srcSession,'mrSESSION.mat'));

if ieNotDefined('srcDt')
    % select from src session's data types
    names = {src.dataTYPES.name};
    [srcDt, ok] = listdlg('PromptString','Import from which data type?',...
                        'ListSize',[400 600],...
                        'SelectionMode','single',...
                        'ListString',names,...
                        'InitialValue',1,...
                        'OKString','OK');
	if ~ok, return; end
end

% make sure specification format is clear:
% srcDt will refer to the data type name, and
% srcDtNum will be the numeric index into dataTYPES:
if ~isnumeric(srcDt)
    srcDtNum = existDataType(srcDt, src.dataTYPES);
else
    srcDtNum = srcDt;
    srcDt = src.dataTYPES(srcDtNum).name;
end

% error check: the source data type should exist
if srcDtNum==0
    error('Data type %s doesn''t exist.',srcDt);
end

if notDefined('srcScan')
    % select from src session/dt's scans
    src = load(fullfile(srcSession, 'mrSESSION.mat'));
    names = {src.dataTYPES(srcDtNum).scanParams.annotation};
    for i = 1:length(names)
        names{i} = sprintf('Scan %i: %s',i,names{i});
    end
    [srcScan, ok] = listdlg('PromptString', 'Import corAnal from which scan?',...
                        'ListSize', [400 600],...
                        'SelectionMode', 'multiple',...
                        'ListString', names,...
                        'InitialValue', 1,...
                        'OKString', 'OK');
	if ~ok, return; end
end

% check that an appropriate corAnal file exists, and if so, load it
corAnalPath = fullfile(srcSession, view.viewType, srcDt, 'corAnal.mat');
if ~exist(corAnalPath, 'file')
    error('No corAnal found for %s %s %s', srcSession, view.viewType, srcDt);
else
    src = load(corAnalPath, 'co', 'amp', 'ph');
end
    
% load source coords, find indices of those
% coordinates contained within view's coords
% disp('Checking source and target coordinates...')
srcCoordsFile = fullfile(srcSession, view.viewType, 'coords.mat');
load(srcCoordsFile, 'coords');
[commonCoords, Isrc, Itgt] = intersectCols(coords, view.coords);
nVoxels = size(view.coords, 2);

% get target data type, scan number:
tgtDtNum = view.curDataType;
tgtDt = dataTYPES(tgtDtNum).name;

% if an existing corAnal file exists for the target session,
% load that up, or else initialize to empty:
savePath = fullfile(dataDir(view), 'corAnal_import.mat');
if exist(savePath, 'file')
    load(savePath, 'co', 'amp', 'ph'); 
else
    co = cell(1, numScans(view));
    amp = cell(1, numScans(view));
    ph = cell(1, numScans(view));
end

% init fields to be 0 (for now; convenient not to have NaNs)
co{tgtScan} = zeros(1, nVoxels);
amp{tgtScan} = zeros(1, nVoxels);
ph{tgtScan} = zeros(1, nVoxels);


% copy over field values
fprintf('Importing corAnal fields from %s %s %i \n', srcSession, srcDt, srcScan)
fprintf('\tto %s %s %i ...\n', mrSESSION.sessionCode, tgtDt, tgtScan);
 
co{tgtScan}(Itgt) = src.co{srcScan}(Isrc);
amp{tgtScan}(Itgt) = src.amp{srcScan}(Isrc);
ph{tgtScan}(Itgt) = src.ph{srcScan}(Isrc);

% save the results
save(savePath, 'co', 'amp', 'ph');
view.co = co; view.amp = amp; view.ph = ph;
% refreshScreen(view);

return