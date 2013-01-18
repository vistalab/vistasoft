function msh = dtiAddLights(msh)
%
%  msh = dtiAddLights(msh)
%
%Author: Wandell
%Purpose:
%   Add lights to the DTI mrMesh window.  The actor numbers are stored in
%   the msh variable.
%

origin = 2*[100,100,100];
[msh,l] = mrmSet(msh,'addlight',[],[],origin);
msh.Actors.lights(1) = l.actor;

origin = 2*[-100,-100,-100];
[msh,l] = mrmSet(msh,'addlight',[],[],origin);
msh.Actors.lights(2) = l.actor;

return;

