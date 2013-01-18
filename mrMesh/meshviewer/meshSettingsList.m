function settings = meshSettingsList(msh)
% Load a list of settings from the MeshSettings.mat file for a given mesh,
% updating any GUI listboxes as well.
%
% USAGE:
%	settings = meshSettingsList([msh=cur mesh of cur view]);
%
%
% ras, 07/07.
if notDefined('msh')
	msh = viewGet(getSelectedVolume, 'CurMesh');
end

% if there is no mesh, then clear the settings and return
if isempty(msh)
    settings = [];
    return
end

meshDir = fileparts(msh.path);
settingsFile = fullfile(meshDir, 'MeshSettings.mat');

if ~exist(settingsFile, 'file')
	fprintf('[%s]: No Settings File Found: %s.\n', mfilename, settingsFile); 
	settings = [];
	return
end

load(settingsFile, 'settings');

%% check for GUI listboxes; update them if found
allH = findobj('Tag', 'MeshSettingsList');
for h = allH(:)'
	if isequal( get(h, 'Type'), 'uicontrol' )
		%% uicontrol listbox: set list name
		% make sure the selected entry (value) is within the range
		% of available settings
		n = get(h, 'Value');
		n = min(n, length(settings)); %#ok<*NODEF>

		set(h, 'String', {settings.name}, 'Value', n);
		
	elseif isequal( get(h, 'Type'), 'uimenu' )
		%% uimenu (gray menu)
		vw = getSelectedGray;		
		
		% if several of these menus are found, find the one belonging to
		% the current view		
		if length(h) > 1
			h = vw.ui.menus.meshSettings;
		end
		
		% if previous submenus exist, get rid of 'em
		a = get(h, 'Children');
		delete(a(1:end-4));
		
		% add a series of menu items to retrieve each stored setting
		for ii = 1:length(settings)
			if ii==1, sep = 'on';	else sep = 'off'; 	end

			cb = sprintf('meshRetrieveSettings(viewGet(%s, ''CurMesh''), ''%s''); ', ...
						 vw.name, settings(ii).name);
			
			uimenu(h, 'Label', settings(ii).name, 'Separator', sep, ...
				   'Callback', cb);
		end
	end
end

return
