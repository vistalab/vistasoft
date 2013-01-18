function vw = importMap(vw, srcMapPath, srcScan, tgtScan, outFileName)
% Import parameter map  from another session into the selected
% data type / scan for the current session. Only works for Volume / Gray
% views, and for sessions which share a common volume anatomy.
%
% vw = importMap(<vw>, <srcMapPath>, <srcScan>, <tgtScan>, <outFileName>);
% 
% If any of the latter three arguments are omitted, pops up a dialog.
% srcMapFile: path to map file to import
% outFileName: filename for imported map (fname only, not full path)
%
% ras, 01/06.
if notDefined('vw'),    vw = getSelectedGray;       end
if notDefined('srcScan'),	srcScan = [];				end
if notDefined('tgtScan'),	tgtScan = vw.curScan;		end

if ~ismember(vw.viewType, {'Volume' 'Gray'})
    error('Sorry, only Volume/Gray Views for now.')
end

mrGlobals;

if notDefined('srcMapPath')
    startDir = fileparts(pwd);
    [f p] = myUiGetFile(startDir, '*.mat', 'Select a map to import');
	if iscell(f)
		for i = 1:length(f)
			srcMapPath{i} = fullfile(p, f{i});
		end
	else
	    srcMapPath = fullfile(p,f);
	end
end

% allow cell array of maps
if iscell(srcMapPath)
	for i = 1:length(srcMapPath)
		vw = importMap(vw, srcMapPath{i}, srcScan, tgtScan);
	end
	return
end

% the session dir should be 2 parent directories above the map data dir
[par srcDt] = fileparts(fileparts(srcMapPath));
srcSession = fileparts(par);

% % load source mrSESSION file
% src = load(fullfile(srcSession,'mrSESSION.mat'));

% check that an appropriate map file exists, and if so, load it
if ~exist(srcMapPath, 'file')
    error(sprintf('%s not found.', srcMapPath));
else
	% we should get the fields 'map' and 'mapName', as well as possible
	% optional fields 'mapUnits' and 'co'.
    src = load(srcMapPath);
end
  
% load source coords, find indices of those
% coordinates contained within vw's coords
% disp('Checking source and target coordinates...')
srcCoordsFile = fullfile(srcSession, vw.viewType, 'coords.mat');
try
    load(srcCoordsFile, 'coords');
catch  % in case the coords file is somewhere else, e.g. not 2 directories above the parent directory as we assume above % amr Jan 10, 2011
    srcCoordsFile = mrvSelectFile('r', 'mat', 'Please select coords file', srcSession);
    load(srcCoordsFile, 'coords');
end
[commonCoords, Isrc, Itgt] = intersectCols(coords, vw.coords);
nVoxels = size(vw.coords, 2);

% get target data type, scan number:
tgtDtNum = vw.curDataType;
tgtDt = dataTYPES(tgtDtNum).name;

% if an existing parameter map file exists for the target session,
% load that up, or else initialize to empty:
mapName = src.mapName;
[p f ext] = fileparts(srcMapPath);
savePath = fullfile(dataDir(vw), [f '.mat']);
if exist(savePath, 'file')
    load(savePath, 'map'); 
else
    map = cell(1, viewGet(vw, 'numScans'));
end

% default source scan, if no scan specified
if notDefined('srcScan')
    tmp = cellfind(src.map);
    if isempty(tmp)
        myErrorDlg('No data found in the map file for any scan!');
    else
        srcScan = tmp(1);
        fprintf('Importing map data from scan %i', srcScan);
    end
end

% % check that the map is defined for the source scan
% if length(src.map) < srcScan | isempty(src.map{srcScan})
%     if prefsVerboseCheck==1
%         fprintf('%s not defined for scan %i, not importing\n', srcMapPath, srcScan);
%     end
%     return
% end

% initialize map volume
map{tgtScan} = zeros(1, nVoxels);

% copy over map data
fprintf('Importing map from %s %s %i \n', srcSession, srcDt, srcScan)
fprintf('\tto %s %s %i ...\n', mrSESSION.sessionCode, tgtDt, tgtScan);

map{tgtScan}(Itgt) = src.map{srcScan}(Isrc);

% check for map units and a 'co' field
if isfield(src, 'mapUnits')
	mapUnits = src.mapUnits;
else
	mapUnits = '';
end

if isfield(src, 'co')
	% copy over the 'co' field as well
	scansToCopy = intersect( cellfind(src.co), 1:numScans(vw) );
	for ii = scansToCopy
		vw.co{ii} = NaN( dataSize(vw) );
		vw.co{ii}(Itgt) = src.co{ii}(Isrc);
	end
end

% save the results
if exist('outFileName', 'var')
    p = dataDir(vw); f = outFileName;
    savePath = fullfile(p,f);
end

if isfield(src, 'co')
	co = vw.co;
	if exist(savePath, 'file')
	    save(savePath, 'map', 'mapName', 'mapUnits', 'co', '-append');
	else
	    save(savePath, 'map', 'mapName', 'mapUnits', 'co');
	end
elseif exist(savePath, 'file')
    save(savePath, 'map', 'mapName', 'mapUnits', '-append');
else
    save(savePath, 'map', 'mapName', 'mapUnits');
end    
vw = setParameterMap(vw, map, mapName);

return