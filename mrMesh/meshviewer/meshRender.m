function view = meshRender(view,mshN);
%
%   view = meshRender(view,mshN);
%
% Author: RFD
% Purpose:
%     Using mrVista data, render one of the meshes (mshN) attached to a
%     VOLUME view.
%
%     A mrMesh window is opened as well, showing the computed mesh.
%
% view = meshRender(VOLUME{1},1);

% Should become obsolete.  We will put all of this into meshVisualize
%

if ieNotDefined('mshN'), mshN = viewGet(view,'selectedmeshn'); end
msh = viewGet(view,'mesh',mshN);
mrmSet(msh,'setdata');

return;
