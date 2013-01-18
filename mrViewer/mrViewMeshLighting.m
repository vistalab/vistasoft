function ui = mrViewMeshLighting(ui, msh, L, distance);
% Set the lighting parameters for a surface mesh.
%
% ui = mrViewMeshLighting(ui, <msh>, <L, distance=dialog>);
%
% ui: mrViewer UI w/ mesh loaded.
%
% msh: mesh structure. Defaults to current mesh in ui.
%
% L: structure with two fields:
%	ambient: [r g b] ambient lighting parameter (not sure details myself?)
%	diffuse: [r g b] diffuse lighting parameter
%
% distance: flag to move lights closer to, or further from, the mesh origin
% (and the mesh). If 1, don't move; <1, move closer; >1, move further away.
%
% If either L or distance are omitted, pops up a dialog.
%
% ras, 04/2008
if notDefined('ui'), ui = mrViewGet;				end
if ishandle(ui),	 ui = get(gcf, 'UserData');		end

msh = mrViewGet(ui,'currentmesh');
lights = meshGet(msh,'lights');

%% put up a dialog for editing lighting levels --
% for this function, we set the coefficients for all
% lights to be the same. Build up an 'L' light struct
% which will eventually be handed to mrMesh:
if iscell(lights)
	L.diffuse = lights{1}.diffuse;
	L.ambient = lights{1}.ambient;
else
	L.diffuse = lights(1).diffuse;
	L.ambient = lights(1).ambient;
end

% get params from dialog, if they're not provided
if notDefined('L') | notDefined('distance')
	% create the dialog
	dlg(1).fieldName = 'ambient';
	dlg(1).style	 = 'edit';
	dlg(1).string	 = 'Ambient Light Level';
	dlg(1).value	 = num2str(L.ambient);

	dlg(2).fieldName = 'diffuse';
	dlg(2).style	 = 'edit';
	dlg(2).string	 = 'Light Diffusion Coeffcient';
	dlg(2).value	 = num2str(L.diffuse);

	dlg(3).fieldName = 'distance';
	dlg(3).style	 = 'edit';
	dlg(3).string	 = ['Move lights closer (<1) or further (>1) ' ...
						'from current distance?'];
	dlg(3).value	 = '1';

	% get the response
	resp = generalDialog(dlg, 'Set Mesh Lighting');

	% parse the response
	L.diffuse = str2num(resp.diffuse);
	L.ambient = str2num(resp.ambient);
	distance  = str2num(resp.distance); 
end

% apply the user settings to each light
host = meshGet(msh, 'host');
windowID = meshGet(msh, 'windowID');
for n = 1:length(lights)
	if iscell(lights)
		L.actor = lights{n}.actor;
		L.origin = distance .* lights{n}.origin;	
		
		lights{n} = mergeStructures(lights{n}, L);
	else
		L.actor = lights(n).actor;
		L.origin = distance .* lights(n).origin;
		
		lights(n) = mergeStructures(lights(n), L);
	end
     mrMesh(host, windowID, 'set', L);
end

% update mesh, lights in ui
msh = meshSet(msh, 'lights', lights);
ui = mrViewSet(ui, 'mesh', msh);

return
