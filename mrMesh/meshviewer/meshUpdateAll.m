function view = meshUpdateAll(view);
% Update all mesh displays associated with a mrVista view.
%
% view = meshUpdateAll([view=cur gray view]);
% 
% ras, 08/2008.
if notDefined('view'),		view = getSelectedGray;		end

if ~isfield(view, 'mesh') | isempty(view.mesh)
	return
end

% remember the currently selected mesh, to restor it later
curMesh = view.meshNum3d;

for ii = 1:length(view.mesh);
	view.meshNum3d = ii;
	view = meshColorOverlay(view);
end

% restore the originally-selected mesh
view.meshNum3d = curMesh;

return
