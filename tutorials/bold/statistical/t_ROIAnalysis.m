% t_ROIAnalysis
%
% Load ROIs and summarize some parameter map values within these ROIs
% 
% Dependencies: 
%   Remote Data Toolbox
%
% This tutorial can either be run as a stand-alone tutorial, using the
% fully processed ernie pRF directory, or as part of a sequence in which
% the ernie pRF directory is built up from raw files.  is part of a
% sequence. For the latter, run the following sequence
% of tutorials
%
%   t_initAnatomyFromFreesurfer
%   t_meshFromFreesurfer 
%   t_initVistaSession
%   t_alignInplaneToVolume 
%   t_installSegmentation  
%   t_sliceTiming       
%   t_motionCorrection  
%   t_averageTSeries  
%   t_atlasAndTemplates
%
% prior to running this tutorial. 
%
% Summary 
%
% - Navigate
% - Load a few ROIs
% - Visualize
% - Clean up
%
% Tested MM/DD/YYYY - MATLAB r2015a (REPLACE WITH VERSION), Mac OS 10.11.6
% (REPLACE WITH YOUR OS)
%
%  See also: t_atlasAndTemplates 
%
% WinawerLab

%% Navigate

% Remember where we are
curdir = pwd();

% Find ernie PRF session in scratch directory
erniePRF = fullfile(vistaRootPath, 'local', 'scratch', 'erniePRF');

if ~exist(erniePRF, 'dir')
    % If we did not find the temporary directory created by prior
    % tutorials, then use the full directory, downloading if necessary        
    erniePRF = mrtInstallSampleData('functional', 'erniePRF');
end

% Clean start in case we have a vista session open
mrvCleanWorkspace();


cd(erniePRF);

% Open a 3-view vista session

% Check that scratch ernie directory has been set up with a intialized
% vistasession
if ~exist(fullfile('Gray', 'coords.mat'), 'file')    
    warning(strcat('It looks like you did not run the pre-requisite tutorials. ', ...
        ' Therefore we will use the already processed session in local/erniePRF ', ...
        ' rather than local/scratch/erniePRF.'))
    erniePRF = mrtInstallSampleData('functional', 'erniePRF');
    cd(erniePRF);
end

vw = mrVista('3');


%% Load a few ROIs 

% Which ROIs are already defined?
roiFiles = dir(fullfile('3DAnatomy', 'ROIs', '*.mat'));
roiNames = arrayfun(@(x) x.name, roiFiles, 'UniformOutput', false);
disp(roiNames)

% Load V1 and V2 rois (there should be 4: a dorsal and ventral for each)
idx = contains(roiNames, 'V1') | contains(roiNames, 'V2');

vw = loadROI(vw, roiNames(idx));

% Confirm that we loaded them successfully
viewGet(vw, 'ROI names')

%% Load the stored angle map from the Orignal Data TYPE
vw = viewSet(vw, 'current DataTYPE', 'Original');

% which parameters maps are in the dataTYPE?
mapFiles = dir(fullfile(dataDir(vw), '*.nii.gz'));
mapNames = arrayfun(@(x) x.name, mapFiles, 'UniformOutput', false);

% Find and load the angle map
idx = contains(mapNames, 'angle');
vw  = loadParameterMap(vw, mapNames{idx});

%% Summarize the angle data by ROI

% Get the whole parameter map
parameterMap = viewGet(vw, 'scanmap', 1);

n = viewGet(vw, 'num ROIs');

figHdl = mrvNewGraphWin('Polar angle map','wide');
subplot(1, n+1,1);
histogram(parameterMap(parameterMap>0)); xlim([0 180])
title('Entire parameter map')


for ii = 1:n
    subplot(1,n+1,ii+1);
    roiName = viewGet(vw, 'ROI name', ii);
    roiIndices = viewGet(vw, 'ROI indices', ii);
    histogram(parameterMap(roiIndices)); xlim([0 180])
    title(roiName)
    xlabel('Polar Angle');
    ylabel('Number of voxels')

end

%% Clean up 
close(vw.ui.figNum);
mrvCleanWorkspace
cd(curdir)