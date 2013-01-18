%% t_meshShowContrast
%
% Illustrates how to project a contrast map onto a 3D mesh
%
% Before proceeding with tutorial:
%	* Run t_initGrayAndVolume.
%	* Run t_glmRun.
%	* Run t_glmComputeContrastMap.
%	* Run t_convertMapInplaneToGray
%
% See also T_INITGRAYANDVOLUME, T_GLMRUN, T_GLMCOMPUTECONTRASTMAP, T_CONVERTMAPINPLANETOGRAY.
%
% JW (c) Stanford VISTA
%

%% Initialize the key variables and data path:
dataDir     = fullfile(mrvDataRootPath,'functional','vwfaLoc');
pathToMesh  = fullfile(mrvDataRootPath, 'anatomy','anatomyNIFTI', 'leftMesh.mat');
pathToMap   = fullfile(dataDir, 'Gray', 'GLMs', 'FixVWordScrambleWord.mat');
displayMode = 'co'; % Co-thresholded display mode
threshold   = .05; % Co-threshold

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

%% Load data structure, parameter map, and 3D mesh
vw_gray = initHiddenGray();
vw_gray = loadParameterMap(vw_gray, pathToMap);
vw_gray = meshLoad(vw_gray, pathToMesh, 1);

%% Select display mode and threshold
vw_gray = viewSet(vw_gray, 'displaymode', 'co');
vw_gray = viewSet(vw_gray, 'cothresh', threshold);

%% Set bicolor colormap (neg and pos values)
vw_gray = bicolorCmap(vw_gray);

%% Overlay contrast map onto mesh
vw_gray = meshColorOverlay(vw_gray); 

%% Restore original directory
cd(curDir);

%% END
