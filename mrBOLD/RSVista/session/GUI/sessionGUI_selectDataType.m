function GUI = sessionGUI_selectDataType(dt);
% Select a mrVista study, updating relevant GUI controls and global
% variables.
%
% GUI = sessionGUI_selectDataType(<data type or uicontrol handle>);
%
% Can provide the name or index of a data type, or else a handle to a 
% uicontrol used to select the data type. 
%
% If the handle to a study control (listbox) is provided, will select the
% session based on the currently-selected value of the uicontrol.
%
% If no argument is provided, will get from the GUI.controls.dataType
% listbox.
%
% The GUI input/output args do not generally need to be called, as this
% function will update the global variable GUI, as well as the mrGlobals
% variables. However, it will formally allow keeping this information in 
% other, independent, structures.
%
% ras, 07/03/06.
mrGlobals2;

if notDefined('dt'), dt = GUI.controls.dataType; end

% parse the format in which dt is specified
if isnumeric(dt) & mod(dt, 1)==0
    % dt is in proper format, don't need to do anything
    
elseif ishandle(dt)
    % get from control w/ this handle
    dt = get(dt, 'Value');
    
elseif ischar(dt)
    % find in current data types list
    dt = cellfind({dataTYPES.name}, dt);
    
end

% select in GUI
set(GUI.controls.dataType, 'String', {dataTYPES.name}, 'Value', dt);
GUI.settings.dataType = dt;

% select in INPLANE / VOLUME views
INPLANE{1}.curDataType = dt;
VOLUME{1}.curDataType = dt;

% update maps listbox to match the maps available for this data type:
% down the line, it'll be nice to have it be specific to the selected
% scans as well, but right now, I see no way to do this without loading
% the maps and checking which entries are empty / nonempty, or unwieldy
% bookkeeping. So, always list the available maps for each data type.
% (Note that 'maps' now includes corAnal fields)
w = what(fullfile(GUI.settings.session, 'Inplane', dataTYPES(dt).name));
if ~isempty(w) & checkfields(w, 'mat')
    mapFiles = w.mat;
else
    mapFiles = {};
end
    
for i=1:length(mapFiles), 
    [p mapFiles{i} ext] = fileparts(mapFiles{i}); 
end
mapFiles = sort(mapFiles);
set(GUI.controls.map, 'String', mapFiles, 'Value', double(~isempty(mapFiles)));


% update scans listbox to match this data type
curScans = guiGet('scans');
if any(curScans > guiGet('numScans'))
	curScans = 1;
end
GUI = sessionGUI_selectScans(curScans);



return
    