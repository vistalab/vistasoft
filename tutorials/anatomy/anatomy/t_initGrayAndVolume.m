%% t_initGrayAndVolume
%
% Illustrates how to initialize the gray and volume views.
%
% Tested 01/04/2011 - MATLAB r2008a, Fedora 12, Current Repos
%
% Stanford VISTA
%

%% Initialize the key variables and data path:
anatDir     = fullfile(mrvDataRootPath,'anatomy','anatomyNIFTI'); % Directory containing anatomies
volAnat     = fullfile(anatDir, 't1.nii.gz'); % Path to volume anatomy
volSegm     = fullfile(anatDir, 't1_class.nii.gz'); % Path to segmentation
dataDir 	= fullfile(mrvDataRootPath,'functional','vwfaLoc');
nGrayLayers = 2;

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

% You must tell Matlab where the data directory is.
global HOMEDIR
HOMEDIR = fullfile(mrvDataRootPath,'functional','vwfaloc');

%% Set the volume anatomy path and load the view:
setVAnatomyPath(volAnat);    % Set the volume path
vw_vol = initHiddenVolume(); % Initialize a volume view

%% Grow necessary gray layers from volume and load the view:
buildGrayCoords(vw_vol, [], [], {volSegm}, nGrayLayers); 

% Initialize a gray view structure
vw_gray = initHiddenGray(); 

%% Restore original directory
cd(curDir);

%% END
