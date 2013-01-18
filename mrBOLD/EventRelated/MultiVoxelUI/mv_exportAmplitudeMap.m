function mv = mv_exportAmplitudeMap(mv);
%
% mv = mv_exportAmplitudeMap(mv);
%
% Create multiple parameter maps, with the amplitude for
% each selected condition in a multivoxel UI.
%
%
% ras, 09/2006.
if notDefined('mv'), mv = get(gcf, 'UserData'); end


% get amplitudes for all selected conditions
amps = mv_amps(mv);
nConds = size(amps, 2);
selConds = find(tc_selectedConds(mv));

% initialize a view to get parameters about the 
% map volume
fn = sprintf('getSelected%s',mv.roi.viewType);
view = eval(fn);
if isempty(view)
    % no selected view of the proper type -- make a hidden one 
    mrGlobals; loadSession; saveFlag = 1;
    fn = sprintf('initHidden%s',roi.viewType); view = eval(fn);
end
mapdims = viewGet(view,'dataSize');
nScans = viewGet(view,'numScans');
scan = mv.params.scans(1);


for c = 1:nConds
    % plug in the values to the map volume:
    mapvol = zeros(mapdims);
    ind = roiIndices(view,mv.coords);
    mapvol(ind) = amps(:,c);

    
    % save map
    mapName = sprintf('Amplitudes_%s_%s_%s', mv.params.ampType, ...
                       mv.trials.condNames{selConds(c)}, mv.roi.name);
    mapPath = fullfile(dataDir(view),mapName);
    if exist(mapPath,'dir')
        load(mapPath,'map','mapName'); 
        map{scan} = mapvol;
    else
        map = cell(1, nScans);
    end    
    map{scan} = mapvol;
    save(mapPath,'map','mapName');
    fprintf('Saved map %s.\n',mapPath);
end

% plug the map volume into the view
fprintf('Assigning %s data to param map for scan %i\n',mapName,scan);
map = cell(1,nScans);
map{scan} = mapvol;
if ~isequal(view.name,'hidden')
    view = setParameterMap(view,map,mapName);
    refreshScreen(view);
end

% evaluate this in the workspace, so the view
% itself is updated
assignin('base','map',map);
evalin('base',sprintf('%s=setParameterMap(%s,map,''%s'');',...
    view.name,view.name,mapName));


return