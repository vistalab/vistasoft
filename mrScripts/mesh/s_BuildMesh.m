%% s_BuildMesh
% This script illustrates a method of building a mesh from a white matter
% class file 
%
% 
% (c) VISTASOFT, Stanford

% You should put the patht= to a legitimate class file here.
% fName = 'C:\u\brian\Matlab\mrDataExample\mrGray_sampleData\anatomy\left\Seg1\left.Class';
fName = fullfile(mrvDataRootPath,'anatomy','anatomyV','left','left.Class');

% This is the name of the class file.  The msh is built.
msh = meshBuildFromClass(fName);

% Visualize the coarse, unshaded mesh
meshVisualize(msh);

% Set up parameters, smooth and visualize the mesh
msh = meshSet(msh,'smooth_relaxation',.5);   
msh = meshSet(msh,'smooth_sinc_method',0);   
msh = meshSet(msh,'smooth_iterations',16);   
msh2 = meshSmooth(msh);
meshVisualize(msh2);

% Shade the mesh using local curvature
msh3 = meshColor(msh2,[],.25);

% Visualize the mesh smoothed and colored with the curvature
meshVisualize(msh3,2);

% Now, visualize a mesh with some gray matter added to it
nLayers = 2;
[nodes,edges,classData] = mrgGrowGray(fName,nLayers); 
mrgDisplayGrayMatter(nodes,edges,80,[120 140 120 140]);
  
% Add the gray matter to the white matter prior to creating the mesh. 
wm = uint8( (classData.data == classData.type.white) ...
    | (classData.data == classData.type.gray) );

% Now do the same sequence as above
msh4 = meshBuildFromClass(wm,[1 1 1]);
msh4 = meshSmooth(msh4);
msh4 = meshColor(msh4);
meshVisualize(msh4,2);




