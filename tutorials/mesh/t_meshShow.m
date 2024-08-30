%% t_meshShow
%
% This script loads a mesh and calls mrMesh to show it.
% 
% To download the test data, including the mrvistadata information,
% look at mrtInstallSampleData
%
% See also:  t_meshFromClass
%
% (c) VISTASOFT, Stanford

% Hack to set Data path
% mrvDataRootPath = fullfile(vistaRootPath, 'local');

%% Load an existing mesh and show it
tmp = load(fullfile(mrvDataRootPath,'anatomy','anatomyNIFTI','leftMesh.mat'));
msh = tmp.msh; clear tmp
msh = meshSet(msh,'actor',33);

windowID = 999;
msh = meshSet(msh,'window id',999);
meshVisualize(msh);

%% End