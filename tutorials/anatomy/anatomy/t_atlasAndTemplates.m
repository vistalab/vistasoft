% t_atlasAndTemplates
%
% Tutorial to make ROIs and templates from Wang maximum probabiltiy atlas
% and from Benson V1-V3 atlas
% 
%
% Dependencies: 
%   Freesurfer
%   Docker
%   Remote Data Toolbox
%
% This tutorial can either be run as a stand-alone tutorial, using the
% fully processed ernie pRF directory, or as part of a sequence in which
% the ernie pRF directory is built up from raw files. For the former, run
%   t_initAnatomyFromFreesurfer
% before running this tutorial. For the latter, run the following sequence
% of tutorials
%   t_initAnatomyFromFreesurfer
%   t_meshFromFreesurfer 
%   t_initVistaSession
%   t_alignInplaneToVolume 
%   t_installSegmentation  
%   t_sliceTiming       
%   t_motionCorrection  
%   t_averageTSeries    
% prior to running this tutorial. 
%
% Summary
%
% - Run Noah Benson's template docker on ernie freesurfer directory
% - Navigate and open the ernie vistasession
% - Open and smooth meshes
% - Create and visualize 25 ROIs from Wang et al maximum probability atlas
% - Create and visualize V1-V3 ROIs from Benson atlas
% - Load and visualize eccentricity and polar angle maps from Benson atlas
%
% Tested 12/5/2016 - MATLAB r2015b, Mac OS 10.12.1
%
%  See also: t_initAnatomyFromFreesurfer t_meshesFromFreesurfer
%  t_initVistaSession t_alignInplaneToVolume t_installSegmentation
%  t_sliceTiming t_motionCorrection t_averageTSeries
%
% Winawerlab, NYU

%% Run Noah Benson's docker on ernie freesurfer directory
%
% Prior to running this tutorial, you can run this docker on the ernie
% freesurrfer directory: https://hub.docker.com/r/nben/occipital_atlas/
%
% If the docker has already been run, then you can skip this cell.
% Otherwise we will run the docker here.
%
% To do so, we need to be sure that 
%   - we have downloaded the ernie freesufer
%   - we have the docker application installed and running
% 
% We can then EITHER enter the following command in a terminal, replacing
% '/path/to/your/freesurfer' with the actual path:
% docker run -ti --rm -v /path/to/your/freesurfer/ernie:/input \nben/occipital_atlas:latest
%
% OR we can call the docker from Matlab. 

% Check whether freesurfer paths exist.
fssubjectsdir = getenv('SUBJECTS_DIR');
if isempty(fssubjectsdir)
    error('Freesurfer paths not found. Cannot proceed.')
end

% Get ernie freesurfer directory and install it in freesurfer subjects dir.
%   If we find the directory, do not bother unzipping again.
forceOverwrite = false;
dFolder = mrtInstallSampleData('anatomy/freesurfer', 'ernie', ...
    fssubjectsdir, forceOverwrite);

fprintf('Freesurfer directory for ernie installed here:\n %s\n', dFolder)

% Now run the docker, first checking whether it has already been run. 
wangAtlasPath = sprintf(fullfile(dFolder, 'mri',...
    'native.wang2015_atlas.mgz'));

if exist(wangAtlasPath, 'file')
    warning(strcat('It looks like the docker was already run on ernie.', ...
        ' We will proceed without re-running the docker.'))
else
    % Run the docker using a system call
    str = sprintf('docker run -ti --rm -v %s:/input \\nben/occipital_atlas:latest', dFolder);
    system(str)
end

if ~exist(wangAtlasPath, 'file')
   error('Cannot find the file %s, which is an expected output of the docker. Cannot proceed', wangAtlasPath);
end
%% Navigate

mrvCleanWorkspace();

% Find ernie PRF session in scratch directory
erniePRF = fullfile(vistaRootPath, 'local', 'scratch', 'erniePRF');

if ~exist(erniePRF, 'dir')
    % If we did not find the temporary directory created by prior
    % tutorials, then use the full directory, downloading if necessary        
    erniePRF = mrtInstallSampleData('functional', 'erniePRF');
end

% Clean start in case we have a vista session open
mrvCleanWorkspace();

% Remember where we are
curdir = pwd();

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

%% Open meshes
mesh1 = fullfile('3DAnatomy', 'Left', '3DMeshes', 'Left_inflated.mat');
mesh2 = fullfile('3DAnatomy', 'Right', '3DMeshes', 'Right_inflated.mat');

if ~exist(mesh1, 'file') || ~exist(mesh2, 'file')
    error('Meshes not found. Please run t_meshFromFreesurfer.')
end
[vw, OK] = meshLoad(vw, mesh1, 1); if ~OK, error('Mesh server failure'); end
[vw, OK] = meshLoad(vw, mesh2, 1); if ~OK, error('Mesh server failure'); end

%% Wang ROIs

% Convert mgz to nifti
[pth, fname] = fileparts(wangAtlasPath);
wangAtlasNifti = fullfile(pth, sprintf('%s.nii.gz', fname));

ni = MRIread(wangAtlasPath);
MRIwrite(ni, wangAtlasNifti);

% Load the nifti as ROIs
vw = wangAtlasToROIs(vw, wangAtlasNifti);

% Save the ROIs
local = false; forceSave = true;
saveAllROIs(vw, local, forceSave);
 
% Let's look at the ROIs on meshes
%   Store the coords to vertex mapping for each ROI for quicker drawing
vw = roiSetVertIndsAllMeshes(vw); 

vw = meshUpdateAll(vw); 

% Copy the mesh to a Matlab figure
hTmp(1) = figure('Color', 'w');
imagesc(mrmGet(viewGet(vw, 'Mesh'), 'screenshot')/255); axis image; axis off; 


% For fun, color the meshes
nROIs = length(viewGet(vw, 'ROIs'));
colors = hsv(nROIs);
for ii = 1:nROIs
   vw = viewSet(vw, 'ROI color', colors(ii,:), ii); 
end
vw = viewSet(vw, 'roi draw method', 'boxes');

vw = meshUpdateAll(vw); 
% Copy the mesh to a Matlab figure
hTmp(2) = figure('Color', 'w');
imagesc(mrmGet(viewGet(vw, 'Mesh'), 'screenshot')/255); axis image; axis off; 


%% Benson ROIs
% LOAD THE BENSON ATLAS AS ROIS (V1-V3)
bensonROIsPath = sprintf(fullfile(dFolder, 'mri',...
    'native.template_areas.mgz'));

[pth, fname] = fileparts(bensonROIsPath);
bensonROIsNifti = fullfile(pth, sprintf('%s.nii.gz', fname));

ni = MRIread(bensonROIsPath); 
MRIwrite(ni, bensonROIsNifti);

% Hide ROIs in the volume view, because it is slow to find and draw the
% boundaries of so many ROIs
vw = viewSet(vw, 'Hide Gray ROIs', true);

% Load the nifti as ROIs
numROIs = length(viewGet(vw, 'ROIs'));
vw = nifti2ROI(vw, bensonROIsNifti);
vw = viewSet(vw, 'ROI Name', 'BensonAtlas_V1', numROIs + 1);
vw = viewSet(vw, 'ROI Name', 'BensonAtlas_V2', numROIs + 2);
vw = viewSet(vw, 'ROI Name', 'BensonAtlas_V3', numROIs + 3);

% Visualize Benson ROIs overlayed on Wang atlas
vw = viewSet(vw, 'ROI draw method', 'perimeter');
vw = meshUpdateAll(vw); 

% Copy the mesh to a Matlab figure
hTmp(3) = figure('Color', 'w');
imagesc(mrmGet(viewGet(vw, 'Mesh'), 'screenshot')/255); axis image; axis off; 


%% Benson eccentricity and polar angle maps

% Find the volumetric maps in the freesurfer directory made by the benson
% docker
bensonEccPath = sprintf(fullfile(dFolder, 'mri',...
    'native.template_eccen.mgz'));
bensonAnglePath = sprintf(fullfile(dFolder, 'mri',...
    'native.template_angle.mgz'));

% ECCENTRICITY -----------------------------------------------------
% Load and display the eccentricity map
[~, fname] = fileparts(bensonEccPath);
writePth = fullfile('Gray', 'Original');
bensonEccNifti = fullfile(writePth, sprintf('%s.nii.gz', fname));
mkdir(writePth);
ni = MRIread(bensonEccPath); 
MRIwrite(ni, bensonEccNifti);

vw = viewSet(vw, 'display mode', 'map');
vw = loadParameterMap(vw, bensonEccNifti);

% use truncated hsv colormap (fovea is red, periphery is blue)
vw.ui.mapMode = setColormap(vw.ui.mapMode, 'hsvTbCmap'); 

% limit to ecc > 0
vw = viewSet(vw, 'mapwin', [eps 90]);
vw = viewSet(vw, 'mapclip', [eps 90]);
vw = refreshScreen(vw);
vw = meshUpdateAll(vw); 

% Copy the mesh to a Matlab figure
hTmp(4) = figure('Color', 'w');
imagesc(mrmGet(viewGet(vw, 'Mesh'), 'screenshot')/255); axis image; axis off; 

% POLAR ANGLE -----------------------------------------------------
% Load and display the angle map
[~, fname] = fileparts(bensonAnglePath);
writePth = fullfile('Gray', 'Original');
bensonAngleNifti = fullfile(writePth, sprintf('%s.nii.gz', fname));
mkdir(writePth);
ni = MRIread(bensonAnglePath); 
MRIwrite(ni, bensonAngleNifti);

vw = viewSet(vw, 'display mode', 'map');
vw = loadParameterMap(vw, bensonAngleNifti);

% use  hsv colormap
vw.ui.mapMode = setColormap(vw.ui.mapMode, 'hsvCmap'); 

% limit to angles > 0
vw = viewSet(vw, 'mapwin', [eps 180]);
vw = viewSet(vw, 'mapclip', [eps 180]);
vw = refreshScreen(vw);
vw = meshUpdateAll(vw); 

% Copy the mesh to a Matlab figure
hTmp(5) = figure('Color', 'w');
imagesc(mrmGet(viewGet(vw, 'Mesh'), 'screenshot')/255); axis image; axis off; 

return

% Clean up
vw = meshDelete(vw, inf);
close(viewGet(vw, 'fignum'));
close(hTmp)
mrvCleanWorkspace
cd(curdir)