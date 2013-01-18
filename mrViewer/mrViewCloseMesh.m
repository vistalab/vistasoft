function ui = mrViewCloseMesh(ui);
%
%  ui = mrViewCloseMesh(ui);
%
% Close a mesh attached to a mrViewer UI, removing that option
% from the list of meshes to select at the same time.
%
% ras, 10/2006.
if notDefined('ui'),        ui = mrViewGet;                     end
if ishandle(ui),            ui = get(ui, 'UserData');           end

s = ui.settings.segmentation;
m = ui.segmentation(s).settings.mesh;

% close the mesh
ui.segmentation(s) = segCloseMesh(ui.segmentation(s));

% remove the menu entry for this mesh 
if checkfields(ui, 'menus', 'meshList')
    delete(ui.menus.meshList(m));
    ok = setdiff(1:length(ui.menus.meshList), m);
    ui.menus.meshList = ui.menus.meshList(ok);
end

% select an appopriate remaining mesh
if ui.segmentation(s).settings.mesh==0
	% no meshes remain for this segmentation
	
else
	newMeshNum = ui.segmentation(s).settings.mesh;
	mrViewSet(ui, 'CurMeshNum', newMeshNum);
end


if ishandle(ui.fig)
    set(ui.fig, 'UserData', ui);
end

return
