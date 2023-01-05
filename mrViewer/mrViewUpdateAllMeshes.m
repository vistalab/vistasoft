function ui = mrViewUpdateAllMeshes(ui);
% Simple function to loop through all meshes loaded in a mrViewer UI, and
% project data onto them.
%
%  ui = mrViewUpdateAllMeshes(ui);
%
% ras, 09/2008. 
if notDefined('ui'),	ui = mrViewGet;					end
if ishandle(ui),		ui = get(ui, 'UserData');		end

% remember what mesh and segmentation were selected, so we can restore them
% at the end
selectedMesh = mrViewGet(ui, 'CurMeshNum');
selectedSegmentation = mrViewGet(ui, 'CurSegmentationNum');

% get list of all meshes
meshList = mrViewGet(ui, 'MeshList');

% loop across, select each in turn, and project data
for n = 1:length(meshList)
	ui = mrViewSelectMesh(ui, n);
	ui = mrViewMesh(ui);
end

% restore the originally selected segmentation, mesh
ui = mrViewSet(ui, 'CurSegmentationNum', selectedSegmentation);
ui = mrViewSet(ui, 'CurMeshNum', selectedMesh);

return

	