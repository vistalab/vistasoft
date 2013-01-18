function ui = mrViewDisplayMesh(ui, msh);
%
% ui = mrViewDisplayMesh(ui, [msh=cur mesh]);
%
% Open a mesh display for the current mesh. Updates the mesh id property, 
% and sets it as the current mesh in the viewer.
%
% ras, 10/2006.
if ~exist('ui', 'var') | isempty(ui),  ui = mrViewGet; end
if ishandle(ui), ui = get(ui, 'UserData'); end
if notDefined('msh'), msh = mrViewGet(ui, 'CurMesh'); end

msh = meshVisualize(msh);

msh = mrmSet(msh, 'cursoroff');

mrViewSet(ui, 'CurMesh', msh);


return
