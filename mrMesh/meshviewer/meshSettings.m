function [settings, msh] = meshSettings(msh);
% Get position, zoom, lighting, background, and cursor settings for a mesh.
%
% [settings, msh] = meshSettings(<msh=selected mesh in selected gray>);
%
%
%
% ras, 03/14/05
if notDefined('msh'), msh = viewGet(getSelectedGray, 'selectedMesh');  end

% get all settings from the camera
settings.camera = mrmGet(msh, 'camera_all');

% get background color (doesn't currently work)
settings.backgroundColor = mrmGet(msh, 'Background');
if isstruct(settings.backgroundColor) % error -- expected
    settings.backgroundColor = [1 1 1];
end

% % get list of actors (generally, 32 will be the mesh itself, and 33-34 will
% % be lights)
% (temp disabled, may be faster just to assume the lights are 33 and 34)
% actors = mrmGet(msh, 'ListOfActors');

% get lighting info
for i = 1:2 % length(actors.objectList)-1
    settings.lights(i) = mrmGet(msh, 'ActorData', i+32);
end

% get cursor location (vertex on mesh)
try 
    settings.cursor = mrmGet(msh, 'CursorVertex');
catch
    settings.cursor = [1];
end

% get current roi
settings.roi = mrmGet(msh, 'CurROI');

% get rotation and origin only of mesh (the rest might change)
settings.mesh.rotation = mrmGet(msh, 'rotation', 32);
settings.mesh.origin = mrmGet(msh, 'origin', 32);

return

