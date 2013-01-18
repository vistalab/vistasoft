function coords = mrmSetCursorCoords(mesh, coords)
%
% coords = mrmSetCursorCoords(mesh, [coords])
%
% If coords is set and non-empty, then we set the position of 
% the 3d cursor in the current mrMesh window. Otherwise, we
% return the current position.
%
% Coords are adjusted using the origin of the mesh and x-y swapped, 
% so they should correspond to the vAnatomy coordinate frame.
%
% TODO:
% *** check to make sure there is no off-by-one error given c/matlab 0/1
% indexing.
%
% HISTORY:
% 2003.11.14 RFD (bob@white.stanford.edu): wrote it.
%

tmp.actor = 1;
if(exist('coords','var') & ~isempty(coords)) 
    if(prod(size(coords))~=3) error('Coords must be 1x3 or 3x1!'); end
    coords = coords(:)';
    tmp.origin = coords([2,1,3]) .* mesh.mmPerVox + mesh.origin;
    [id,stat,res] = mrMesh(mesh.host,mesh.id, 'set', tmp);
else
    tmp.get_origin = 1;
    [id,stat,res] = mrMesh(mesh.host,mesh.id, 'get', tmp);
    coords = res.origin - mesh.origin;
    coords = coords([2,1,3]) ./ mesh.mmPerVox;
end
return;