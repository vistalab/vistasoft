%% t_pRF
%
% Solve pRF model in the INPLANE view using sample data set <erniePRF>
%
% Dependencies: 
%   Remote Data Toolbox
%
%
% Summary
% - Solve pRF models on the INPLANE data using the averaged data set
% 
% Tested 09/25/2016 - MATLAB R2015a, Mac OS 10.11.6 (Silvia Choi's computer)  
%
%  See also: t_pRF
%
%  Winawer lab (NYU)

%% Navigate

% Store the current path so we can return at the end
curpath = pwd();

% Navigate and open vistasession
erniePRF = fullfile(vistaRootPath, 'local', 'erniePRF'); 
cd(erniePRF)

% Open hidden view
vw = initHiddenInplane();

% We will use the averaged data stored in dataTYPES to solve the pRF model
vw = viewSet(vw, 'Current DataTYPE', 'Averages');
vw = rmLoadParameters(vw);

%% Solve

% Solve it! This will take several hours. 
vw = rmMain(vw, [], 'coarse to fine and hrf', ...
    'model', {'onegaussian'}, 'matFileName','rmOneGaussian'); 

%% Clean up
cd(curpath);
close all;
mrvCleanWorkspace();


