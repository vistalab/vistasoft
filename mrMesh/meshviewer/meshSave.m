function view = meshSave(view, mshID)
% Appears to be obsolete.  See mrmWriteMeshFile.
% 
% Save a mesh attached to a mrVista Gray or Volume view.
% Usage:
%  view = meshSave(view, <meshNumber>);
%   or
%  view = meshSave(view, <meshSavePath>);
%
% Where <meshNumber> is the index into the view's loaded meshes, and
% meshSavePath is a string describing the path to save the mesh. If
% omitted, will save the currently-selected mesh in the path
% assigned to that mesh.
%
% ras, 06/06: written to complement meshLoad.

disp('Tell Brian Wandell you saw this meshSave message')

if notDefined('view'), view = getCurView; end

if ~ismember(view.viewType, {'Volume' 'Gray'})
    error('Works only on Volume or Gray views.')
end

if notDefined('mshID'), mshID = viewGet(view, 'selectedMeshN'); end

if isnumeric(mshID)
    % index into view.mesh field:
    msh = view.mesh{mshID};
    savePath = msh.path;
elseif ischar(mshID)
    % save path
    msh = viewGet(view, 'selectedMesh');
    savePath = mshID;
else
    help(mfilename)
    error('Invalid format for 2nd argument.')
end

[msh savePath] = mrmWriteMeshFile(msh, savePath);

return

