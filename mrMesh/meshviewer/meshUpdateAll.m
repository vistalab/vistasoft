function vw = meshUpdateAll(vw)
% Update all mesh displays associated with a mrVista view.
%
% vw = meshUpdateAll([vw=cur gray view]);
% 
% ras, 08/2008.
if notDefined('vw'), vw = getSelectedGray; end

if ~isfield(vw, 'mesh') || isempty(viewGet(vw, 'mesh'))
	return
end

% remember the currently selected mesh, to restore it later
curMesh = viewGet(vw, 'mesh num');

for ii = 1:length(viewGet(vw, 'allmeshes'))
	vw = viewSet(vw, 'mesh num', ii);
	vw = meshColorOverlay(vw);
end

% restore the originally-selected mesh
vw = viewSet(vw, 'mesh num', curMesh);

return
