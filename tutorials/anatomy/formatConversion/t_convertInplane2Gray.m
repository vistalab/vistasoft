%% t_convertMapInplaneToGray
%
% Illustrates how to convert a parameter map in the inplane view to gray space.
%
% Before proceeding with tutorial:
%	* Run t_initGrayAndVolume.
%	* Run t_glmRun.
%	* Run t_glmComputeContrastMap.
%
% See also T_INITGRAYANDVOLUME, T_GLMRUN, T_GLMCOMPUTECONTRASTMAP.
%
% Tested 01/04/2011 - MATLAB r2008a, Fedora 12, Current Repos
%
% Stanford VISTA
%

%% Initialize the key variables and data path
dataType    = 'GLMs'; % The relevant parameter map is of the GLMs data type
dataDir     = fullfile(mrvDataRootPath,'functional','vwfaLoc');
pathToMap   = fullfile(dataDir, 'Inplane', 'GLMs', 'fixVcheckerboardWordScramble.mat');

%% Retain original directory, change to data directory
curDir = pwd;
chdir(dataDir);

%% Initialize the inplane view, set the data type to GLMs, and load the
% parameter map created in t_glmComputeContrastMap
vw_ip       = initHiddenInplane();
vw_ip       = viewSet(vw_ip, 'currentDataType', dataType);
vw_ip   	= loadParameterMap(vw_ip, pathToMap);

%% Initialize the gray view and set the data type to GLMs
vw_gray     = initHiddenGray();
vw_gray     = viewSet(vw_gray, 'currentDataType', dataType);

%% Set up and run conversion routine 
scans   = 0; % Flag to convert for all scans
saveMap = 1; % Force save of volume map?
method  = 'linear'; % Trilinear interpolation (alternative: 'nearest')
vw_gray  = ip2volParMap(vw_ip, vw_gray, scans, saveMap, method);

%% Return to the original directory.
chdir(curDir);

%% END 
