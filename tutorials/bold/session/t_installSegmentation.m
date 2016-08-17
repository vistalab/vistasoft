%% t_installSegmentation
%
% Illustrates how to align the inplane volume from an fMRI session to the
% 3D volume anatomy using sample data set <erniePRF>
%
% Dependencies: 
%   Remote Data Toolbox
%
% This tutorial is part of a sequence. Run 
%   t_initAnatomyFromFreesurfer
%   t_initVistaSession
%   t_alignInplaneToVolume
% prior to running this tutorial. 
%
% Summary
%
% - Specify alignment matrix linking inplane anatomy to volume anatomy
% - Save mrSESSION with alignment matrix
%
% Tested 07/21/2016 - MATLAB r2015a, Mac OS 10.11.6 
%
%  See also: t_initAnatomyFromFreesurfer t_initVistaSession t_alignInplaneToVolume
%
% Winawer lab (NYU)

%% Start
% Clean start in case we have a vista session open
mrvCleanWorkspace();

% Remember where we are
curdir = pwd();

%% Organize functional data

% Find ernie PRF session in scratch directory
erniePathTemp      = fullfile(vistaRootPath, 'local', 'scratch', 'erniePRF');

if ~exist(erniePathTemp, 'dir')
    help(mfilename)
    error('Please run  pre-requisite tutorials')
end

% Navigate and create a directory
cd(erniePathTemp)

%% Align inplane to t1 and install Gray/white segmentation

% Open a hidden view
vw = initHiddenInplane();

% Segmentation inputs
%   use command line, not dialog
query = false;       

%   keep all gray nodes, including those outside functional FOV
keepAllNodes = true; 

%   path to class file
filePaths = fullfile('3DAnatomy', 't1_class.nii.gz');

%   number of layers in gray graph along surface (3 layers for 1 mm voxels)
numGrayLayers = 3;

% Do it
installSegmentation(query, keepAllNodes, filePaths, numGrayLayers);


%% Visualize

% open a UI
vw = mrVista;

% Define an ROI that is the entire functional slab
vw = makeGrayROI(vw); 
vw = refreshScreen(vw,0);

% add the local variable, vw, to the UI in case you would like to interact
% with the GUI
updateGlobal(vw)

%% Clean up
close(viewGet(vw, 'figure number')); 
mrvCleanWorkspace
cd(curdir)