%% t_convertTalMNI2Volume
%
% Illustrates how to grow discs around coordinates from MNI or Talairach space.
%
% Before proceeding with tutorial:
%	* Run t_initGrayAndVolume.
%	* Run t_meshCreate, create a left hemisphere mesh, and save out leftMesh.mat.
%
% See also T_INITGRAYANDVOLUME, T_MESHCREATE.
%
% Stanford VISTA
%

%% Initialize the key variables and data path
dataDir     = fullfile(mrvDataRootPath, 'functional', 'vwfaLoc');
pathToMesh  = fullfile(mrvDataRootPath, 'anatomy', 'anatomyNIFTI', 'leftMesh.mat');

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

%% Choose coordinates near VWFA for demonstration
coords      = [-42 -60 -12];
radius      = 10;
roi_name    = 'Middle Temporal';

%% Load grown disk into a gray view structure 
vw_gray = findTalairachVolume([], 'path', pwd, 'Talairach', coords, 'name', roi_name, 'radius', radius); 

%% Open 3D mesh and load it into the gray view structure.
vw_gray = meshLoad(vw_gray, pathToMesh, 1);

%% Recompute relationship between vertices and gray nodes, set ROI draw method
%to a filled perimeter, and refresh the mesh. 
vw_gray = viewSet(vw_gray, 'recomputev2gmap'); 
vw_gray = viewSet(vw_gray, 'roidrawmethod', 'filled perimeter'); % other options: 'boxes', 'filled perimeter', 'patches'
vw_gray = meshColorOverlay(vw_gray); 

% Return to the original directory
cd(curDir);

%% END
