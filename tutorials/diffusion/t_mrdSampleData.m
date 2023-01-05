% t_mrdSampleData
%
% Bring up a mrDiffusion data with sample data.
%
% See also: t_mrd, t_mrdWindow, and other t_mrd*
%
% Brian (c) Stanford VISTASOFT Team, 2012

%% Open a window, but make it invisible
dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
dt6Name = fullfile(dataDir,'dti40','dt6.mat');
mrDiffusion('on',dt6Name);

%% End