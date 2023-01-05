% t_mrdWindow
%
% Illustrate how to find the mrDiffusion window if you didn't save the
% figure or handles.
%
% See also: t_mrd
%
% Brian (c) Stanford VISTASOFT Team, 2012

% dtiGetValFromTensors

%% Open a window, but make it invisible
dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
dt6Name = fullfile(dataDir,'dti40','dt6.mat');
mrDiffusion('off',dt6Name);

%% Find the window
dtiF = dtiGet([],'main figure');
figure(dtiF)

% Get the figure handles
dtiH = guihandles(dtiF);
dtiH2 = dtiGet([],'handles');
isequal(dtiH,dtiH2)

%% End