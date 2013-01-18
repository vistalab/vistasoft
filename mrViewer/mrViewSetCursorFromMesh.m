function ui = mrViewSetCursorFromMesh(ui, msh);
%
% ui = mrViewSetCursorFromMesh(ui, msh);
% 
% Set the cursor in a mrViewer UI to agree with the 
% cursor position mapped in the mesh msh, if possible.
% Otherwise, warn user.
%
% 
% ras, 07/06.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet;        end
if ishandle(ui), ui = get(ui, 'UserData'); end

if ~exist('msh', 'var') | isempty(msh), msh = mrViewGet(ui, 'CurMesh'); end

seg = mrViewGet(ui, 'CurSegmentation');

% get the vertex # of the cursor on the mesh:
vtx = mrmGet(msh, 'cursorvertex');

if vtx < 1
    myWarnDlg('Sorry, the mesh cursor isn''t within these data.');
    return
end

% get coordinate of nearest layer 1 node for the vertex
nodes = segGet(seg, 'nodes');
I = msh.vertexGrayMap(1,vtx); 
loc = nodes([2 1 3],I)';	

% match location to the viewer's coordinate space,
% xforming if necessary
spaceNames = {ui.mr.spaces.name};
N = cellfind(spaceNames, 'I|P|R'); % gray matter space = 'I|P|R'
if isempty(N)
	error('Can''t find transform between the viewer and mesh coordinates.');
end

if ~isequal(ui.mr.spaces(N).xform, eye(4))
	% apply an xform, only if it's needed
	loc = coordsXform(inv(ui.mr.spaces(N).xform), loc(:));
end	

ui = mrViewSet(ui, 'CursorLoc', round(loc));
ui = mrViewSet(ui, 'Slice', round(loc(3)));

return
