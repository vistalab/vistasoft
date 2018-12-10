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

if ~exist(erniePath, 'dir')
    % If we did not find the temporary directory created by prior
    % tutorials, then use the full directory, downloading if necessary        
    erniePath = mrtInstallSampleData('functional', 'erniePRF');
end

% Install Ernie freesurfer directory and ernie vistasession
cd(erniePath);

% Create and save meshes
hemi = 'b';
surfaces = {'white' 'pial' 'sphere' 'inflated'};
[meshes, fnames] = meshImportFreesurferSurfaces('ernie', hemi, surfaces);

%% Visualize 
    
% View the 4 left meshes: white, pial, inflated, sphere

for ii = 1:4
    meshVisualize(meshes(ii)) 
    % This call should open a new application, mrMeshMac or a related name
    % (depending on your OS), if it is not already open. Then it will open a
    % new window and show the mesh. You can rotate, zoom, and translate with
    % the appropriate mouse actions. We BELIEVE that the mouse buttons are as
    % follows:
    %   Rotation:  left mouse button plus movement
    %   Zoom:      right mouse button plus up/down movement
    %   Translate: left and right together plus movement

end



%% Alernative visualiztion in Matlab

for m = 1:4
    
    figure,
    
    % Faces (also called triangles) are defined by 3 points, each of
    % which is an index into the x, y, z vertices
    faces = meshes(m).triangles' + 1; % we need to 1-index rather than 0-index for Matlab
    
    % The vertices are the locations in mm spacing
    x     = meshes(m).vertices(1,:)';
    y     = meshes(m).vertices(2,:)';
    z     = meshes(m).vertices(3,:)';
    
    % The colormap will, by default, paint sulci dark and gyri light
    c     = meshes(m).colors(1,:)';
    
    % Render the triangle mesh
    tH = trimesh(faces, x,y,z);
    
    % Make it look nice
    set(tH, 'LineStyle', 'none', 'FaceColor', 'interp', 'FaceVertexCData',c)
    axis equal off; colormap gray; set(gca, 'CLim', [0 255])
    
    % Lighting to make it look glossy
    light('Position',100*[0 1 1],'Style','local')
    lighting gouraud
    
    % Which mesh are we plotting?
    title(meshes(m).name)
    
    % Rotate it
    set(gca, 'View', [-16.7000  -90.0000]);
    
end


