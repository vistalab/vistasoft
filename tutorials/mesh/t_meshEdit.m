% t_meshEdit
% Script (tutorial) to create, edit and visualize a mesh.
%
% See also T_MESHCREATE, MRGSAVECLASSWITHGRAY.
%
% Stanford VISTA
%

%% See t_meshCreate for a little more on creating meshes
dataD = mrvDataRootPath;
fName = fullfile(dataD,'anatomy','anatomyNIFTI','t1_class.nii.gz');

% Run the build code
msh = meshBuildFromClass(fName,[],'left');
msh = meshSmooth(msh);
msh = meshColor(msh);

% Visualize the coarse, unshaded mesh
meshVisualize(msh);

%% Set up parameters, smooth and visualize the mesh
msh = meshSet(msh,'smooth_relaxation',1);   
msh = meshSet(msh,'smooth_sinc_method',0);   
msh = meshSet(msh,'smooth_iterations',200);   
msh2 = meshSmooth(msh);
meshVisualize(msh2);

%% Shade the mesh using local curvature
msh3 = meshColor(msh2,[],.25);

% Visualize the mesh smoothed and colored with the curvature
meshID = 2;
meshVisualize(msh3,meshID);

%% Now, visualize a mesh with some gray matter added to it
% We will add two gray layers
nLayers = 2;

% We use mrgGrowGray to read the WM and create new nodes/edges and white
% matter class data.
[nodes,edges,classData] = mrgGrowGray(fName,nLayers); 

% mrgDisplayGrayMatter(nodes,edges,80,[120 140 120 140]);
  
% Add the gray matter to the white matter prior to creating the mesh. 
wm = uint8( (classData.data == classData.type.white) ...
    | (classData.data == classData.type.gray) );

% We should add to meshBuildFromClass function an argument that specifies
% how many gray layers to add.  Then we could skip this step and just start
% below.

%% Now do the same sequence as above
mmPerVox = 0.7*[1,1,1];
msh4 = meshBuildFromClass(wm,mmPerVox);
msh4 = meshSmooth(msh4);
msh4 = meshColor(msh4);
meshVisualize(msh4,2);

%% END
