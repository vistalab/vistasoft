%% t_glmComputeContrastMap
%
% Illustrates how to compute a contrast map for later projection onto a 3D
% mesh.
% 
% Before proceeding with tutorial:
%	* Run t_glmRun.
%
% See also T_GLMRUN.
%
% Tested 01/04/2011 - MATLAB r2008a, Fedora 12, Current Repos
%
% Stanford VISTA
%

%% Initialize the key variables and data path:
% Data directory (where the mrSession file is located)
dataDir = fullfile(mrvDataRootPath,'functional','vwfaLoc');
dataType = 'MotionComp';

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

%% Retrieve data structure and set data type:
vw_ip = initHiddenInplane();
vw_ip = viewSet(vw_ip, 'currentDataType', dataType);

%% Get information re: the experiment/trials:
stimuli = er_concatParfiles(vw_ip);
nConds = length(stimuli.condNums);

%% Print condition numbers and names for input into contrast fxn:
fprintf('[##] - Condition Name\n');
fprintf('---------------------\n');
for i = 1:nConds
    fprintf('[%02d] - %s\n', stimuli.condNums(i), stimuli.condNames{i});
end

%% Choose active and control conditions:
activeConds     = [0]; % Fixation
% versus
controlConds    = [1 2]; % Word & WordScramble

% Choose a name for the contrast - left empty to assign default
contrastName    = []; 

vw_ip = viewSet(vw_ip, 'currentDataType', 'GLMs');
%% Compute the contrast map for view on mesh:
computeContrastMap2(vw_ip, activeConds, controlConds, contrastName);

%% Return to the original directory.
cd(curDir);

%% END

