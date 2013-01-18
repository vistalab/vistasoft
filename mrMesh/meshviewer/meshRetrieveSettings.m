function [msh, settings] = meshRetrieveSettings(msh, n);
% Store Settings in a mesh, updating any GUIs that reflect this.
%  
% [msh, settings] = meshRetrieveSettings(msh, <n>);
%
% Applies mesh viewing settings stored in a UI. n can be an index into the
% settings vector, or a name of a setting. If omitted, finds it from the 
% uicontrol with the tage 'MeshSettingsList' (and errors if it can't find
% that).
%
% If the special flag 'all' is entered as the first argument, then the mesh
% name or number is applied to all meshes assigned to the selected gray
% view.
%
% Returns the mesh and the settings struct which was retrieved.
%
% SEE ALSO: meshSettings, meshApplySettings.
%
% ras, 03/14/06.
if notDefined('msh'), msh = viewGet(getSelectedGray, 'selectedMesh');  end

% special case: apply the desired setting to all meshes
if ischar(msh) & isequal(lower(msh), 'all')
	G = getSelectedGray;
	for m = 1:length(G.mesh)
		try
			[msh settings{m}] = meshRetrieveSettings(G.mesh{m}, n);
		catch
			fprintf('[%s]: Setting %s not found for mesh %i.\n', ...
					mfilename, num2str(n), m);
		end
	end
	return
end

% get the listbox control
h = findobj('Tag', 'MeshSettingsList');
h=double(h);
if notDefined('n')
    if isempty(h)
        error('Only works with a Mesh Settings UI');
    else
        n = get(h, 'Value');
    end
end

% get the saved settings
meshDir = fileparts(msh.path);
if isempty(meshDir)
    meshDir = viewGet(getSelectedGray, 'meshDir');
end

settingsFile = fullfile(meshDir, 'MeshSettings.mat');
if exist(settingsFile, 'file')
    load(settingsFile, 'settings');
else
    settings = [];
end

% allow names to be passed in
if ischar(n)
    names = {settings.name};
    n = cellfind(names, n);
    if isempty(n)
        error('The requested setting was not found.')
    end
end

% apply the selected settings
msh = meshApplySettings(msh, settings(n));

return

