function GUI = sessionGUI_loadMap(maps, viewer);
% Load a map (incl. Traveling Wave Analysis field) into 
% the current mrVista 2 MR Viewer.
%
% GUI = sessionGUI_loadMap(<maps=get from GUI>, <viewer handle>);
%
% maps can be a path to a map file, an index in the GUI's current
% map list, a name relative to the INPLANE data dir, or a cell array
% of these specifications.
%
% Note this is currently designed to load inplane maps only,
% as the mrVista 2 tools interpolate into different spaces 
% (including the Volume 'I|P|R' space) on the fly.
%
% By default, loads the map into the MR viewer specified by 
% GUI.settings.viewer. But if a handle to a different viewer
% is passed in, will load into that one instead. If no viewer
% is open, opens an inplane viewer and loads the map into that.
%
% ras, 07/2006.
mrGlobals2;

if notDefined('maps'), maps = GUI.controls.map; end
if notDefined('viewer')
    if isempty(GUI.viewers)
        viewer = sessionGUI_viewInplane;
	else
		viewer = guiGet('viewer');
    end
end


% parse the format of the maps arg, getting it into the format
% of a cell array of file paths
if iscell(maps)
    % check that each entry is a path
    for i = 1:length(maps)
        maps{i} = sessionGUI_mapPath(maps{i});
    end
    
elseif isnumeric(maps) & all(mod(maps, 1)==0)
    % index into ROIs list
    for i = 1:length(maps)
        mapList{i} = sessionGUI_mapPath(maps(i));
    end
    maps = mapList;
    
elseif ishandle(maps)
    % get from uicontrol
    maps = get(maps, 'Value');
    for i = 1:length(maps)
        mapList{i} = sessionGUI_mapPath(maps(i));
    end
    maps = mapList;
    
elseif ischar(maps)
    maps = {sessionGUI_mapPath(maps)};

else
    error('Invalid map specification. ')
    
end


% Now that we have a cell array of paths, load each one into the current
% viewer:
for i = 1:length(maps)
    % check for corAnal file
    [p f ext] = fileparts(maps{i});
    if strncmp(f, 'corAnal', 7)
        mrViewLoad(viewer, maps{i}, 'map', '1.0corAnal', guiGet('scans'));
    else
        mrViewLoad(viewer, maps{i}, 'map', '1.0map', guiGet('scans')); 
    end
end


return
% /--------------------------------------------------------------------/ %






% /--------------------------------------------------------------------/ %
function pth = sessionGUI_mapPath(map);
% return a full path to an ROI file, given the name of an ROI in the
% current ROI list, or the numeric index. If a full path is already 
% provided, return it unchanged.
mrGlobals2;

if ischar(map) & exist(map, 'file') 
    pth = fullpath(map); 
    
elseif isnumeric(map) 
    mapNames = get(GUI.controls.map, 'String');
    pth = fullfile(dataDir(INPLANE{1}), mapNames{map(1)});
    
elseif ischar(map)
%     if get(GUI.controls.mType, 'Value')==1  % inplane
        parent = dataDir(INPLANE{1});
%     else        % volume
%         parent = dataDir(VOLUME{1});
%     end
    pth = fullfile(parent, map);
    
    [p f ext] = fileparts(pth);
    if isempty(ext), pth = [pth '.mat']; end
    
else
    error('Invalid ROI specification. ')
    
end

pth = [pth '.mat'];

