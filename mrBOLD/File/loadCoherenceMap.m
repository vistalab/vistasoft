function view = loadCoherenceMap(view, mapFile, scaleFlag);
% Load a map into a view's 'coherence' slot, scaling if selected.
%
%  view = loadCoherenceMap([view], [mapFile=dialog], [scaleFlag=1]);
%
% INPUTS:
%	view: mrVista view. [Defaults to current view.]
%
%	mapFile: name/path of map file. [Default: prompt the user.]
%
%	scaleFlag: if 1, scale map to [0 1] by dividing by max(abs(map)).
%	If 0, will load it directly (will warn if the map values are
%	outside [0 1], but do nothing else). If 2, will divide the absolute value 
%	of the map by 100 (this is done, for instance, when loading -log(p)
%	maps: so  co=0.01 will threshold at p < 0.1, and co=0.02 at p < 0.01, etc.)
%	[default 1, scale]
%
% OUTPUTS: view with the map loaded into the 'co' field.
% 
% NOTE: I realize this is very similar to loadParameterMapIntoCoherenceMap.
% That function would take a pre-loaded map in the view.map field, and
% auto-transfer it to view.co. This function doesn't require the 2-step,
% and has the option not to scale the map (useful for measures like
% proportion variance explained, which already lie in [0 1] but may not
% contain 0 or 1).
%
% ras, 07/2008.
if notDefined('view'),		view = getCurView;		end
if notDefined('scaleFlag'),	scaleFlag = 1;			end
if notDefined('mapFile'),	
	ttl = 'Load map file into coherence slot';
	[mapFile ok] = mrvSelectFile('r', {'mat'; '*'}, ttl, dataDir(view));
	if ~ok, disp('loadCoherenceMap aborted.'); return; end
end
	
% make sure map file is an absolute path -- may be specified relative to
% the view's dataDir:
if ~check4File(mapFile)
	altPath = fullfile(dataDir(view), mapFile);
	if check4File(altPath)
		mapFile = altPath;
	else
		error('File not found.')
	end
end

load(mapFile, 'map');

% check size
checkSize(view, map);

% rescale
switch scaleFlag
	case 0, % do nothing
	case 1, % divide by max(abs(map))
		for s = 1:length(map)
			map{s} = abs( map{s} ./ max(abs( map{s}(:) )) );
		end
	case 2, % divide by 100, take abs
		for s = 1:length(map)
			map{s} = abs( map{s} ./ 100 );
		end
end

% attach to view
view.co = map;

return

