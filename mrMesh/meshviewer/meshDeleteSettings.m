function msh = meshDeleteSettings(msh, n, forceDelete);
% Store Settings in a mesh, updating any GUIs that reflect this.
%  
% msh = meshDeleteSettings(msh, <n=get from GUI>, <forceDelete=0>);
%
% Delete a stored setting from a mesh. If n is omitted, gets it from the
% uicontrol with the tag 'MeshSettingsList'.
% forceDelete: if 1, will delete w/o asking user for confirmation.
%
% SEE ALSO: meshSettings, meshApplySettings.
%
% ras, 03/14/06.
if notDefined('msh'), msh = viewGet(getSelectedGray, 'selectedMesh');  end
if notDefined('forceDelete'), forceDelete = 0;                         end

% get the settings list
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

% if the mesh to delete isn't specified, get from the settings list
if notDefined('n')
	% the settings list can be a popup menu (as in the 
	% 3D Window or mrViewer mesh panel), or a uimenu (gray menu)	
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
		n = get(h, 'Value'); % index of selected mesh
			
    end
end

% user confirm
if forceDelete==0
    q = sprintf('Permanently delete settings %s?', settings(n).name);
    resp = questdlg(q, mfilename);
    if ~isequal(resp, 'Yes'), return; end
end

% remove the selected settings entry
remaining = setdiff(1:length(settings), n);
settings = settings(remaining);

% update the uicontrol (if it's there)
if ishandle(h) & isequal( get(h, 'Type'), 'uicontrol' )
	set(h, 'String', {settings.name}, 'Value', length(settings));
end

% save the settings
save(settingsFile, 'settings');

return

