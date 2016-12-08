% t_meshFromFreesurfer
%
% Illustrates how to create mrVista compatible meshes from a freesurfer
% surface.
% 
%
% Dependencies: 
%   Remote Data Toolbox
%   Freesurfer paths
%
% This tutorial is part of a sequence. Run 
%   t_initAnatomyFromFreesurfer
% prior to running this tutorial. 
%
% Summary 
%
% - Do actiom A
% - Do action B
% - Visualize
% - Clean up
%
% Tested 09/14/2016 - MATLAB r2015b, Mac OS 10.11.6
%
%  See t_initAnatomyFromFreesurfer
%
% NYU Winawer lab


%% Download ernie freesurfer directory
% Note that this is also done in the prior tutorial,
% t_initAnatomyFromFreesurfer. Doing it a second time won't hurt anyone,
% and it will make this tutorial work on its own, even without running the
% prior one in the sequence.

% Check whether freesurfer paths exist
fssubjectsdir = getenv('SUBJECTS_DIR');
if isempty(fssubjectsdir)
    error('Freesurfer paths not found. Cannot proceed.')
end

% Get ernie freesufer1 directory and install it in freesurfer subjects dir
%   If we find the directory, do not bother unzipping again
forceOverwrite = false; 

% Do it
dFolder = mrtInstallSampleData('anatomy/freesurfer', 'ernie', ...
    fssubjectsdir, forceOverwrite);

fprintf('Freesurfer directory for ernie installed here:\n %s\n', dFolder)

%% Create Freesurfer meshes

% mrVista Project directory
erniePath      = fullfile(vistaRootPath, 'local', 'scratch', 'erniePRF');

% Freesurfer directory with sample subject
fsPath      = getenv('SUBJECTS_DIR');

% Create the left mesh from freesurfer's white matter surface, called
% lh.white. We could also create one from the pial surface, called lh.pial
%   Read in the freesufer surface
fsSurface   = fullfile(fsPath, 'ernie', 'surf', 'lh.white');
%   Convert it to vista style mesh
msh         = fs_meshFromSurface(fsSurface);
msh.name    = 'leftWhite';

% Save the left mesh in our mrVista session
savepth     = fullfile(erniePath, '3DAnatomy', 'Left', '3DMeshes');
mkdir(savepth)
save(fullfile(savepth, 'leftMeshUsmoothedFS'), 'msh');

% rename the mesh for later visualization
leftMsh = msh;
leftMsh.title = 'Left Mesh, Gray/White Boundary';

% Now do the same for the right mesh
fsSurface = fullfile(fsPath, 'ernie', 'surf', 'rh.white');
msh = fs_meshFromSurface(fsSurface);
msh.name    = 'rightWhite';
savepth = fullfile(erniePath, '3DAnatomy', 'Right', '3DMeshes');
mkdir(savepth)
save(fullfile(savepth, 'rightMeshUsmoothedFS'), 'msh');


% rename the mesh for later visualization
rightMsh = msh;
rightMsh.title = 'Right Mesh, Gray/White Boundary';

% Let's do a pial surface just for comparison (but we won't save it)
fsSurface = fullfile(fsPath, 'ernie', 'surf', 'rh.pial');
rightPialMsh = fs_meshFromSurface(fsSurface);
rightPialMsh.title = 'Right Mesh, Gray/Pial Boundary';


%% Visualize 
    
% View the meshes
meshVisualize(leftMsh)

% This call should open a new application, mrMeshMac or a related name
% (depending on your OS), if it is not already open. Then it will open a
% new window and show the mesh. You can rotate, zoom, and translate with
% the appropriate mouse actions. We BELIEVE that the mouse buttons are as
% follows:
%   Rotation:  left mouse button plus movement
%   Zoom:      right mouse button plus up/down movement
%   Translate: left and right together plus movement

% Visualize the right mesh
meshVisualize(rightMsh)

% Visualize the right pial mesh. Note that there is less space in the
% sulci, because the mesh is at the gray-pial boundary rather than the
% white-gray boundary
meshVisualize(rightPialMsh)

%% Alernative visualiztion in Matlab

for msh = {leftMsh, rightMsh, rightPialMsh}
    
    figure,
    
    % Faces (also called triangles) are defined by 3 points, each of
    % which is an index into the x, y, z vertices
    faces = msh{1}.triangles' + 1; % we need to 1-index rather than 0-index for Matlab
    
    % The vertices are the locations in mm spacing
    x     = msh{1}.vertices(1,:)';
    y     = msh{1}.vertices(2,:)';
    z     = msh{1}.vertices(3,:)';
    
    % The colormap will, by default, paint sulci dark and gyri light
    c     = msh{1}.colors(1,:)';
    
    % Render the triangle mesh
    tH = trimesh(faces, x,y,z);
    
    % Make it look nice
    set(tH, 'LineStyle', 'none', 'FaceColor', 'interp', 'FaceVertexCData',c)
    axis equal off; colormap gray; set(gca, 'CLim', [0 255])
    
    % Lighting to make it look glossy
    light('Position',100*[0 1 1],'Style','local')
    lighting gouraud
    
    % Which mesh are we plotting?
    title(msh{1}.title)
    
    % Rotate it
    set(gca, 'View', [-16.7000  -90.0000]);
    
end


