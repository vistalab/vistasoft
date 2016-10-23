%% t_initAnatomyFromFreesurfer
%
% Illustrates how to initialize the volume anatomy and class file from a
% freesurfer directory. Uses the sample freesurfer data set <ernie>
%
% Dependencies: 
%   Freesurfer
%   Remote Data Toolbox
%
% Summary
%
% - Download freesurfer ernie directory 
% - Create t1 anatomy and t1 class files from freesurfer
% - Visualize the two images
%
% Tested 07/20/2016 - MATLAB r2015a, Mac OS 10.11.6 
%
% See also: t_initVistaSession
%
% Winawer lab (NYU)


%% Download ernie freesurfer directory

% Check whether freesurfer paths exist
fssubjectsdir = getenv('SUBJECTS_DIR');
if isempty(fssubjectsdir)
    error('Freesurfer paths not found. Cannot proceed.')
end

% Get ernie freesufer1 directory and install it in freesurfer subjects dir
%   If we find the directory, do not bother unzipping again
forceOverwrite = false; 

% Do it
dataDir = mrtInstallSampleData('anatomy/freesurfer', 'ernie', ...
    fssubjectsdir, forceOverwrite);

fprintf('Freesurfer directory for ernie installed here:\n %s\n', dataDir)


%% Create t1 anatomy and t1 class files from freesurfer
% Store current directory
curdir = pwd(); 

%       This is the path where we will set up the vista session
erniePathTemp      = fullfile(vistaRootPath, 'local', 'scratch', 'erniePRF');
mkdir(erniePathTemp);

% Navigate 
cd(erniePathTemp)

% Create t1 anatomy and class file
mkdir 3DAnatomy;
outfile = fullfile('3DAnatomy', 't1_class.nii.gz');
fillWithCSF = true;
alignTo = fullfile(dataDir, 'mri', 'orig.mgz');
fs_ribbon2itk('ernie', outfile, fillWithCSF, alignTo);
 
% Check that you created a t1 class file (ribbon) and t1 anatomy
ls 3DAnatomy  

% The command window should show:
%       t1.nii.gz	t1_class.nii.gz

%% Visualize

% Show the volume anatomy, segmentation, and anatomy masked by segmentation
ni = niftiRead(fullfile('3DAnatomy', 't1.nii.gz'));
t1 = niftiGet(ni, 'data');
ni = niftiRead(fullfile('3DAnatomy', 't1_class.nii.gz'));
cl = niftiGet(ni, 'data');

fH = figure('Color','w');

% Choose one slice to visualize from the middle of head
sliceNum = size(t1,3)/2;

% Volume anatomy, 
subplot(1,3,1)
imagesc(t1(:,:,sliceNum), [0 255]); colormap gray; axis image
title('Volume anatomy')

subplot(1,3,2)
imagesc(cl(:,:,sliceNum), [1 6]);   axis image
title('Class file')

subplot(1,3,3)
mask = cl(:,:,sliceNum) > 1;
imagesc(t1(:,:,sliceNum) .* uint8(mask));   axis image
title('Masked anatomy')

%% Clean up
cd(curdir)