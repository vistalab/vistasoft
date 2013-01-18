function msh = meshStoreSettings(msh, name);
% Store Settings in a mesh, updating any GUIs that reflect this.
%  
% msh = meshStoreSettings(msh, <name='Setting#'>);
%
% This code will use the meshSettings command to grab mesh view settings,
% and append the result to the msh.settings field, creating it if it
% doesn't exist. In addition, if a uicontrol is found with the tag 
% 'MeshSettingsList', will update the string in this code to reflect the
% new setting. 
%
% Also saves it in a meshDir/'MeshSettings.mat' file, since the mesh 
% saving/loading has gotten complicated.
%
% ras, 03/14/06.
if notDefined('msh'), msh = viewGet(getSelectedGray, 'selectedMesh');  end

% get the saved settings
meshDir = fileparts(msh.path);
if isempty(meshDir)
    meshDir = viewGet(getSelectedGray, 'meshDir');
end

settingsFile = fullfile(meshDir, 'MeshSettings.mat');
if exist(settingsFile, 'file')
    load(settingsFile, 'settings');
    N = length(settings) + 1; %#ok<NODEF>
else
    N = 1;
end

if notDefined('name')
    name = sprintf('Setting%i',N);
end

S = meshSettings(msh);
S.name = name;
settings(N) = S;

% look for a uicontrol from a mesh setting GUI
h = findobj('Tag', 'MeshSettingsList');

if length(h) > 1
    % more than one menu/list open: loop through lists
    for ii = 1:length(h)
       if isequal( get(h(ii), 'Type'), 'uimenu' ) && ...
           get( get(h(ii), 'Parent'), 'Parent' )==gcf
            h = h(ii);
            break
       end
    end
end

if ~isempty(h)
	% ras 11/07: this can either be a uicontrol listbox (as in the 3D
	% Window and mrViewer) or a uimenu (in the new gray menu)
	if isequal( get(h, 'Type'), 'uicontrol' )
	    set(h, 'String', {settings.name});
		
	elseif isequal( get(h, 'Type'), 'uimenu' )
		%% make a submenu
		
		% (prompt for a name now, since renaming later is a little less
		% convenient)
		prompt = {'Enter the new name for the mesh settings'};
	    name = inputdlg(prompt, mfilename, 1, {settings(N).name});
		if isempty(name), return; end   % exit gracefully if cancel

		% the callback should retrieve the selected settings
		cb = sprintf('meshRetrieveSettings([], %i); ', N);
		
		% if this is the first stored setting, we want a separator between
		% this and the other options (store, rename, delete); otherwise, no
		% separator:
		if N==1, sep = 'on'; else sep = 'off'; end
		
		uimenu(h, 'Label', name{1}, 'Callback', cb, 'Separator', sep);
		
		% set this as the name in the settings
		settings(N).name = name{1}; %#ok<NASGU>
	end
end

% save the settings
save(settingsFile, 'settings');

return

