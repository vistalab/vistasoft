function [params ok] = mrInitGUI
% GUI to collect parameters for initializing a mrVista session.
%
% [params ok] = mrInitGUI; 
%
% returns a structure which can be used as input to mrInit2 to convert
% data into the mrVista anatomies and time series, initialize a
% mrSESSION.mat file, and do specified preprocessing. This code consists of
% a series of dialogs to get relevant information -- serving as a 'wizard'
% of sorts to collect the initialization parameters. 
%
% The first dialog is the main dialog (mrInitGUI_main), in which the 
% required fields params.inplanes and params.functionals (described below 
% with the other params) are specified, as well as options for 
% additional parameters the user may want to specify. Subsequent dialogs are 
% presented, if the user requests, to do the following:
%   * enter descriptions of the session and scans, and additional comments
%     about scanning (mrInitGUI_description);
%   * set traveling-wave / event analysis parameters
%     (mrInitGUI_analParams);
%   * specify preprocessing steps, such as motion compensation, time slice
%     acquisition correction, traveling wave, and GLM analyses
%     (mrInitGUI_preprocessing).
%   
%
% Fields for params struct:
%     inplane (*required*): path to inplane anatomies. These are
%     generally T1-weighted MR images coregistered to the functionals.
%     Default: look for the folder Raw/Anatomy/Inplane.    
% 
%     functionals (*required*): cell array of paths to functional time
%     series for each scan. Default: check for mr files in Raw/Pfiles
%     or, failing that, Raw/Functionals.
%
%     vAnatomy: if this file is specified and exists, will set the 
%     reference anatomy to be this file. The volume anatomy, and the
%     other files in the 'anatomy path' where the vAnatomy resides, are not
%     required for Inplane analyses, but are needed for Volume, Gray, and
%     Flat analyses. Gray matter segmentations should reside in the anatomy
%     path. Unlike earlier version of mrVista, the vAnatomy need not be in
%     the mrGray *.dat format, but can be other files such as ANALYZE or
%     NIFTI. 
%
%     sessionDir: directory of session to initialize. Default: pwd.
% 
%     sessionCode: name of session. Default: get from directory name.
% 
%     subject: subject name. Default: get from inplane header.
% 
%     description: description of session. Default: empty.
% 
%    annotations: {1 x nScans} cell array of strings specifying the
%           initial annotation for each scan. (This is displayed at the top in
%           mrVista windows, and in the scan list for mrVista2.)
%           Default is 'scan1' through 'scanN'.
% 
%    parfile: {1 x nScans} list of parfile paths for each scan. These
%           can be absolute, or relative to Stimuli/parfiles/. Default
%           is empty.
% 
%    nCycles: [1 x nScans] set of # of cycles for traveling wave
%           analyses, to be stored in dataTYPES.blockedAnalysisParams.
%           Default is all [8], a guess at the likely value.
% 
%   scanGroups: cell array specifying sets of scans to group together
%           for event-related analyses. Default empty.
% 
%   motionComp: flag to do motion correction. 0: don't do it; 1 do
%           between scans; 2 do within scans; 3 do both between and
%           within scans. Default is 0. Currently this only supports
%           the "Nestares" code motion compensation, although the
%           SPM-based code should be added down the line (it can be run
%           from within mrVista).
% 
%   sliceTimingCorrection: if 1, will perform slice timing correction
%           before any other preprocessing. Default: 0, don't.
% 
%   motionCompRefScan: reference scan if running between-scans motion
%           compensation.
% 
%   motionCompRefFrame: reference frame if running within-scans motion
%           compensation.
%
% ras, 05/2007.

% initialize params to defaults
params = mrInitDefaultParams;

% get initial params / dialog selections
[params ok] = mrInitGUI_main(params);
if ~ok, return;  end

% if specified, add session / scan descriptions
if params.doDescription==1
    params = mrInitGUI_description(params);
end

% if specified, clip temporal frames
if params.doSkipFrames==1
    params = mrInitGUI_skipFrames(params);
end


% if specified, assign analysis parameters
if params.doAnalParams==1
    params = mrInitGUI_analParams(params);
end

% if specified, add session / scan descriptions
if params.doPreprocessing==1
    params = mrInitGUI_preprocessing(params);
end

return
