function saveParameterMap(vw, pathStr, forceSave, saveCmap)
%
% function saveParameterMap(vw, [pathStr], [forceSave], [saveCmap])
%
% save the currently set parameter map in a user specified file
%
% If you change this function make parallel changes in:
%   saveCorAnal, saveParameterMap
%
% If forceSave is set to 1, will not prompt before saving.
%
% saveCmap: if set to 1, will save the map mode parameters as well
% (such as the color map, and the clip mode). [Default: 1, save it]
% 
% 
% rmk, 1/12/99
% djh, 2/2001, mrLoadRet 3.0
% ras, 1/05, added forceSave
% ras, 11/05, added saveCmap
if notDefined('forceSave'),       forceSave = 0;     end
if notDefined('saveCmap'),        saveCmap = 1;       end
if isempty(vw.map)
    warndlg('No Parameter Map is set!');
    return;
end

% if no filename, bring up a dialog box
if notDefined('pathStr')
    if ~isempty(vw.mapName)
        pathStr = fullfile(dataDir(vw),[vw.mapName,'.mat']);
    else
        pathStr = ('path.mat');%putPathStrDialog(dataDir(vw),'Parameter map filename:','*.mat');
   end
end

verbose = prefsVerboseCheck;

if exist('pathStr','var')
    % check if file already exists:
    if exist(pathStr,'file') && forceSave==0
        msg = sprintf('File "%s" already exists.  Overwrite?', pathStr);
        saveFlag = questdlg(msg, 'Save File', 'Yes', 'No', 'No');
    else
        saveFlag = 'Yes';
    end
    
    if strcmp(saveFlag,'Yes')
        if verbose
            fprintf('Saving Parameter Map: %s\n', pathStr);
        end
        
        map = vw.map;
        mapName = vw.mapName;
        mapUnits = vw.mapUnits;
        
        save(pathStr, 'map', 'mapName', 'mapUnits');
	else
		saveCmap = 0;
        disp('Parameter map not saved.');
    end
end

if saveCmap==1 & checkfields(vw, 'ui', 'mapMode') %#ok<AND2>
    cmap =       vw.ui.mapMode.cmap; %#ok<*NASGU>
    clipMode =   vw.ui.mapMode.clipMode;
    numColors =  vw.ui.mapMode.numColors;
    numGrays =   vw.ui.mapMode.numGrays;
    
    save(pathStr, 'cmap', 'clipMode', 'numColors', 'numGrays', '-append');
end

return
