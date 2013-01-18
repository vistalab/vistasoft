function view = meshCloseWindow(view,whichMesh)
%
%    view = meshCloseWindow(view,whichMesh)
%
%Author: Wandell
%Purpose:
%   Close a window with a mesh view in it.

if ieNotDefined('whichMesh'), whichMesh = viewGet(view,'currentmeshnumber'); end

% Get the currently selected mesh 
mesh = viewGet(view,'mesh',whichMesh);
if ~isempty(mesh), mrmSet(mesh,'close');
else warndlg('No open mesh views.'); return; end

mesh = meshSet(mesh,'window',-1);
view = viewSet(view,'mesh',mesh,whichMesh);

end

