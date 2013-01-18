function msh = meshRenameSettings(msh, name, n);
% Store Settings in a mesh, updating any GUIs that reflect this.
%  
% msh = meshRenameSettings(msh, <name=get from dialog>, <whichSetting=get from GUI>);
%
% Rename a mesh's stored setting,
%
% SEE ALSO: meshSettings, meshApplySettings.
%
% ras, 03/14/06.
% ras, 11/04/07: added 'whichSetting' arg, has user select from the stored
% settings if this isn't provided and the GUI can't be found.
if notDefined('msh'), msh = viewGet(getSelectedGray, 'selectedMesh');  end

% get the saved settings
meshDir = fileparts(msh.path);
if isempty(meshDir)
    meshDir = viewGet(getSelectedGray, 'meshDir');
end

settingsFile = fullfile(meshDir, 'MeshSettings.mat');
if exist(settingsFile, 'file')
    load(settingsFile, 'settings');
else
    warning('No setting file found.')
	return
end

if notDefined('n')
	% try to get either from an existing listbox (3D Window, mrViewer)
	% or from a dialog (gray menu)
	h = findobj('Tag', 'MeshSettingsList');
    
    if length(h) > 1
        % more than one menu/list open: loop through lists
        for ii = 1:length(h)
            if isequal( get(h(ii), 'Type'), 'uimenu' ) & ...
                    get( get(h(ii), 'Parent'), 'Parent' )==gcf
                h = h(ii);
                break
            end
        end
    end

    
	if isempty(h) | isequal( get(h, 'Type'), 'uimenu' )
		% have user select from a dialog
		dlg.fieldName = 'whichSetting';
		dlg.style = 'listbox';
		dlg.string = 'Rename which mesh view settings?';
		dlg.list = {settings.name};		
		dlg.value = 1;
		
		resp = generalDialog(dlg, mfilename);
		
		n = cellfind({settings.name}, resp.whichSetting{1});
	else
		% get from existing listbox control
		n = get(h, 'Value'); % index of selected mesh
		
	end
end

if notDefined('name')
    prompt = {'Enter the new name for the mesh settings'};
    name = inputdlg(prompt, mfilename, 1, {settings(n).name});
    if isempty(name), return; end   % exit gracefully if cancel
    name = name{1};
end

% update the name
settings(n).name = name;

% update the uicontrol (if it's there)
if ishandle(h) & isequal( get(h, 'Type'), 'uicontrol' )
	set(h, 'String', {settings.name});
end
	
% save the settings
save(settingsFile, 'settings');

return

