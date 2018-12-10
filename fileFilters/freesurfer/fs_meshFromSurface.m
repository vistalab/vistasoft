function msh = fs_meshFromSurface(fsSurface)
% Create a vistasoft-comptible mesh from a freesurfer surface
%  msh = fs_meshFromSurface(surfaceFile)
%
% Input:
%   fsSurface: path to freesurfer surface file
% Output:
%   msh: vistasoft compatible mesh
%
% Example:
%   fsPath = getenv('SUBJECTS_DIR');
%   fsSurface = fullfile(fsPath, 'wlsubj004', 'surf', 'lh.white');
%   msh = fs_meshFromSurface(fsSurface);
%   meshVisualize(msh)

[initVertices, initFaces] = freesurfer_read_surf(fsSurface);

% We need row vectors for coordinates in vistasoft
vertices = initVertices';
faces    = initFaces';

% There is a 0.5 voxel difference in freesurfer coordinates, as their
%   origin is in the center of a voxel, not a corner
vertices = bsxfun(@plus, vertices, [-.5 .5 -.5]');

% We need to reorient dimensions and shift by 128. The shift is because
% Freesufer's origin is in the center of the image, and for vistasoft it's
% in the corner
vertices = vertices([2 3 1],:)+128;

% Two of the three dimensions are opposite polarity
vertices([1 2],:) = 256 - (vertices([1 2],:));

% Create a standard mesh and add vertices and triangles
msh = meshCreate;
msh.initVertices = vertices;
msh.triangles = faces-1;   % vista triangles are zero indexed
msh.vertices = msh.initVertices;
msh.colors = ones(4, size(msh.vertices,2))*128;


% Construct surface normals
TR = triangulation(msh.triangles'+1, msh.vertices');
VN = vertexNormal(TR);
msh.normals = VN';

% Smooth and color
msh = meshSmooth(msh);
msh = meshColor(msh);

return

%% debug

% build a mesh using vistasoft tools
classfile = '/Volumes/server/Projects/Retinotopy/IndividualTemplates/data/Winawer/wl_subj004/3DAnatomy/t1_class.nii.gz';
vs.msh = meshBuildFromClass(classfile, [1 1 1], 'left'); % 'right' also works
vs.msh = meshSmooth(vs.msh);
vs.msh = meshColor(vs.msh);


fsPath = getenv('SUBJECTS_DIR');
fsSurface = fullfile(fsPath, 'wl_subj004', 'surf', 'lh.white');
fs.msh = fs_meshFromSurface(fsSurface);

% Visualize the meshes
meshVisualize(fs.msh);
meshVisualize(vs.msh);