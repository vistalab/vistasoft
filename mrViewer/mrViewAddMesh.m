function ui = mrViewAddMesh(ui, msh);
% ui = mrViewAddMesh(ui, msh);
%
% Add and select a mesh to a mrViewer UI.
% Adds a menu option to select the mesh in the mesh menu.
%
% ras, 11/01/06.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet;        end
if ishandle(ui), ui = get(ui, 'UserData'); end
if ~exist('msh', 'var') | isempty(msh), error('Need mesh!'); end

% allow mesh paths to be specified
if ischar(msh)
    pth = msh;
    msh = mrmReadMeshfile(pth);
    if isempty(msh)
        error('Couldn''t find mesh file.');
    end
end
    
% clear the vertex -> gray map:
% this may be temporary, but right now, it is often saved in a
% screwed-up state
msh.vertexGrayMap = [];

% add the mesh
s = ui.settings.segmentation;
ui.segmentation(s).mesh{end+1} = msh;
m = length(ui.segmentation(s).mesh);
 
% add a menu option to select this mesh
ui.menus.meshList(m) = uimenu( ui.menus.meshSelect(s+1), ...
        'Label', ui.segmentation(s).mesh{end}.name, ...
        'Callback', sprintf('mrViewSet(gcf, ''CurMeshNum'', %i); ', m) );

ui = mrViewSet(ui, 'CurMeshNum', m);

return
