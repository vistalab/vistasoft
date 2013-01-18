function msh = dtiMrMeshInit(id)
%
%   msh = dtiMrMeshInit(id)
%
%Author: Wandell
%Purpose:
%    Initialize the msh parameters for the mrMesh window

if ieNotDefined('id'), id = 174; end

msh.host = 'localhost';
msh.id = id;
msh.fiberGroupActors = [];
msh.imgActors = [34,35,36];     % Axial, Coronal, Sagittal image planes
msh.Actors.lights = [32,33];    % Two light sources
msh.transparency = 1.0;         % GUI settable.

return;