function GUI = sessionGUI_selectScan(scans);
% Select Scans in the mrVista Session GUI.
%
% GUI = sessionGUI_selectScan(<scans=get from GUI>);
%
% scans can be an array of scan numbers, or a handle to a GUI
% control by which the scans are selected. It defaults to getting
% it from the session GUI scan listbox.
%
%
% ras, 07/2006
mrGlobals2;

if notDefined('scans'), scans = GUI.controls.scan; end

% parse the format for the scans argument
if isnumeric(scans) & all(mod(scans, 1)==0) 
    % scan number/s specified, do nothing
elseif ishandle(scans)
    scans = get(scans, 'Value');
else
    error('Invalid format for scans argument.')
end

% select in GUI
dt = GUI.settings.dataType;
annotations = {dataTYPES(dt).scanParams.annotation};
for s = 1:length(dataTYPES(dt).scanParams)
	scanNames{s} = sprintf('%i.  %s', s, annotations{s});
end
set(GUI.controls.scan, 'String', scanNames, 'Value', scans);

% set in GUI settings
GUI.settings.scan = scans;

% also set first scan in INPLANE/VOLUME views
% (old, so can only have one selected scan at once)
INPLANE{1}.curScan = scans(1);
VOLUME{1}.curScan = scans(1);

return

    