function msh = meshToggleCursor(msh)
% Toggle the visibility of a mesh cursor.
%  
% msh = meshToggleCursor([msh]);
%
% ras, 11/04/2007.
if notDefined('msh'),	msh = viewGet( getSelectedGray, 'Mesh' );	end

% I have to use a persistent variable here, since I can''t find a way to read
% if the cursor is visible from the mesh:
persistent meshCursor  % this should be 1 if cursor is on, 0 if off.

if isempty(meshCursor)
	% initialize to 1: most meshes start w/ the cursor visible.
	meshCursor  = 1;
end

% toggle the value
meshCursor = ~meshCursor;

% set the appropriate property in the mesh
vals = {'hidecursor' 'showcursor'};
mrmSet(msh, vals{meshCursor + 1});

return
