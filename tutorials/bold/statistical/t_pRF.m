%% t_pRF
%
% Defines a stimulus and solves a pRF model in the gray view, after
% transforming the averaged data from inplane (EPI space) to volume (gray
% matter). Uses sample data set <erniePRF>
%
% Dependencies: 
%   Remote Data Toolbox
%
% This tutorial is part of a sequence. Run 
%   t_initAnatomyFromFreesurfer
%   t_meshesFromFreesurfer *optional
%   t_initVistaSession
%   t_alignInplaneToVolume 
%   t_installSegmentation  
%   t_sliceTiming
%   t_motionCorrection
%   t_averageTSeries
% prior to running this tutorial. 
%
% Summary
% - Resample averaged data from inplane to volume 
% - Visualize and install stimulus for pRF model
% - Add the stimulus to the vistasoft view structure and dataTYPES
% - Solve the pRF model
%
% Tested 09/23/2016 - MATLAB R2015a, Mac OS 10.11.6 (Silvia Choi's computer)  
%
%  See also: t_initAnatomyFromFreesurfer t_meshesFromFreesurfer
%  t_initVistaSession t_alignInplaneToVolume t_installSegmentation
%  t_sliceTiming t_motionCorrection t_averageTSeries
%
%  Winawer lab (NYU)

%% Navigate

% Find ernie PRF session in scratch directory
erniePathTemp      = fullfile(vistaRootPath, 'local', 'scratch', 'erniePRF');
cd(erniePathTemp); 

%% Transform averaged data from inplane (EPI space) to volume (gray view)

% Open hidden inplane and gray views
ip  = initHiddenInplane(); 
vol = initHiddenGray(); 

% Set them both to the 'Averages' dataTYPE
ip  = viewSet(ip,  'Current DataTYPE', 'Averages');
vol = viewSet(vol, 'Current DataTYPE', 'Averages');

% Check how many scans (in this case, should be just one)
scans = 1:viewGet(ip, 'num scans'); 

% Tranform the time series using trilinear interpolation
vol = ip2volTSeries(ip, vol, scans, 'linear'); 

%% Visualize the stimulus

% If we use a custom stimulus, rather than one of the pre-specified options
% in Vistasoft, then we need a 'Stimuli' folder for the stimulus files

% Create 'Stimuli' folder
mkdir('Stimuli');

% This is the path where we downloaded the raw MRI data in the first
% tutorial 't_initAnatomyFromFreesurfer'
erniePRFOrig = fullfile(vistaRootPath, 'local', 'erniePRF'); 

% Let's copy 2 files from the Stimuli folder in erniePRFOrig
copyfile(fullfile(erniePRFOrig, 'Stimuli', '8_bars_images.mat'), sprintf('Stimuli%s', filesep));
copyfile(fullfile(erniePRFOrig, 'Stimuli',  '8_bars_params.mat'), sprintf('Stimuli%s', filesep)); 

% Check 'Stimuli' folder 
ls Stimuli
% The command window should show: 
% 8_bars_images.mat,  8_bars_params.mat

% Let's look at what's in these 2 stimulus files:
% (1) The '8_bars_images.mat' file contains a variable called 'images',
% which is a 3D array containing 513 images
f = matfile(fullfile('Stimuli', '8_bars_images.mat')); 
disp(size(f.images))

% (2) The '8_bars_params.mat' file was saved by Vistadisp. It contains many
% details for running the experiment, as well as subject responses. We do
% not need most of these variables. Relevant variables include:
%   params.radius:          stimulus radius (in degrees of visual angle)
%   params.prescanDuration: number of seconds which we expect to be
%                           ignored by the pRF analysis
%   stimulus.seq:           the sequence of images shown, indexing 'images'
%   stimulus.seqtiming:     the time each image was shown in seconds
f = matfile(fullfile('Stimuli', '8_bars_params.mat')); 
disp(f.params); disp(f.stimulus);

% Let's generate the experimental stimuli
load(fullfile('Stimuli', '8_bars_images'), 'images');
load(fullfile('Stimuli', '8_bars_params'), 'params');
load(fullfile('Stimuli', '8_bars_params'), 'stimulus');

% Note that the program recorded a prescan of 12 seconds, and a tr of 1.5s.
% This means that the screen was blank during the first 8 MRI volumes
% acquired. By default, vistasoft will clip these first 12 seconds from
% the stimulus when building a pRF model. This is appropriate for this data
% set, since we discarded the first 8 volumes in preprocessing, and kept
% the rest.
disp(params.prescanDuration)
disp(params.tr)
disp(mrSESSION.functionals(1).keepFrames)

% Let's view the stimulus and skip the prescan period. For frames per
% second, we will compute reciprocal of the difference in frame to frame
% timing
idx = stimulus.seqtiming > params.prescanDuration;
fps = round(1/median(diff(stimulus.seqtiming)));
implay(images(:,:,stimulus.seq(idx)), fps);

% Now a movie player window should open, which displays a high contrast
% checkerboard bar stationed at the left. When you play the movie, the bar
% moves through several orientations in two opposing directions with short
% blank intervals.

%% Install stimulus for pRF models

% Open hidden gray view
vw = initHiddenGray;

% Get stimulus into dataTYPES
vw = viewSet(vw, 'Current DataTYPE', 'Averages');

% Load the stimulus parameter file. We want to check the stimulus size.
% Other parameters will be read directly from this file by code.
load(fullfile('Stimuli', '8_bars_params'), 'params');

% Set default retinotopy stimulus model parameters
sParams = rmCreateStim(vw);

% Now add relevant fields
sParams.stimType   = 'StimFromScan'; % this means the stimulus images will be read from a file
sParams.stimSize   = params.radius;  % stimulus radius (in degrees visual angle)
sParmas.nDCT       = 1;              % detrending frequeny maximum (cycles per scan): 1 means 3 detrending terms, DC (0 cps), 0.5 cps, and 1 cps  
sParams.imFile     = fullfile('Stimulus', '8_bars_images.mat'); % file containing stimulus images
sParams.paramsFile = fullfile('Stimulus', '8_bars_params.mat'); % file containing stimulus parameters
sParams.imFilter   = 'thresholdedBinary'; % when reading in images, treat any pixel value different from background as a 1, else 0
sParams.hrfType    = 'two gammas (SPM style)'; % we switch from the default, positive-only Boynton hRF to the biphasic SPM style
sParams.prescanDuration = params.prescanDuration/params.framePeriod; % pre-scan duration will be stored in frames for the rm, but was stored in seconds in the stimulus file

n = viewGet(vw, 'Current DataTYPE');
dataTYPES(n).retinotopyModelParams = [];
dataTYPES(n) = dtSet(dataTYPES(n), 'rm stim params', sParams);

saveSession();

% Check it
vw = rmLoadParameters(vw);
[~, M] = rmStimulusMatrix(viewGet(vw, 'rm params'));

% Note that what goes into the model is a contrast mask of the stimulus,
% not the actual pixel values of the original stimulus.

%% Run the pRF model

% This might take several hours
vw = rmMain(vw, [], 'coarse to fine and hrf', ...
    'model', {'onegaussian'}, 'matFileName','rmOneGaussian'); 

%% Clean up
close all;
mrvCleanWorkspace; 
