function ctrParams = ctrInitBatchParams(varargin)
%  Initialize the parameters structure used with ctrInitBatchTrack when
%  doing multi-subject tractography using the conTrack algorithm. 
% 
%  ctrParams = ctrInitBatchParams([varargin])
% 
% VARIABLES:
%    ctrParams ...
%      .projectName = ctrParams.projectName = ['myConTrackProj']; 
%                     This variable will be used in the name of all the
%                     files that are created. E.g., outFile =
%                     ['fg_',projectName,'_',roi1,'_',roi2,'_',timeStamp,'.
%                     pdb'];                       
%      .logName     = ctrParams.logName- = ['myConTrackProj']; 
%                     This will be used to provide a unique name for easy
%                     ID in the log directory. 
%      .baseDir     = Top-level directory containing your data. 
%                     The level below baseDir should have each subjects
%                     data directory.
%                     * e.g., ctrParams.baseDir = '/biac/wandell/data/dti/';
%      .dtDir       = This should be the name of the directory containing 
%                     the dt6.mat file.* Relative to the subjects directory.
%                     * e.g., ctrParams.dtDir = 'dti40trilinrt';.
%      .roiDir      = Directory containing the ROIs. * Relative to the
%                     subjects directory.
%                     * e.g., ctrParams.roiDir = 'ROIs';
%      .subs        = This is the cell array that will contain the names 
%                     of all the sujbect's directories that will be
%                     processed. 
%                     * e.g., ctrParams.subs = {'sub1','sub2','sub3'};
%                     NOTE: This script also supports the ability to load a
%                     list of subjects from a text file. If you wish to do
%                     this simply leave the cell empty. You will be
%                     prompted to select a text file that contains a list
%                     of subjects. Please assure that this list is a simple
%                     text file with only subject names seperated by new
%                     lines or spaces. * This can also be a path to a text
%                     file with subject IDs. 
%      .roi1/roi2   = These two cell arrays should contain the names of
%                     each ROI to be used in tracking. The script will
%                     track from ROI1{1} to ROI2{1} and ROI1{2} to ROI2{2}
%                     etc... Use .mat files, but DO NOT include file
%                     extensions. In case that you wish to track from
%                     multiple rois (ROI1) to the same roi (ROI2) you can
%                     just place the name of one roi in ROI2 and each roi
%                     in ROI1 will be tracked to the single roi in ROI2.
%                     * e.g., ctrParams.roi1 = {'Roi1a','Roi1b'}; 
%                             ctrParams.roi2 = {'Roi2a','Roi2b'};
%      .nSamples     = [50000];    % Enter the number of pathway samples to generate.
%      .maxNodes     = [240];      % Enter the max length of the samples.
%      .minNodes     = [10];       % Enter the minimum length of the samples.
%      .stepSize     = [1];        % Enter the step size.
%      .pddpdfFlag   = [0];        % 0 = Only compute if file does not already exist. 1= Always recompute.
%      .wmFlag       = [0];        % 0 = Only compute if file does not already exist. 1= Always recompute.
%      .roi1SeedFlag = ['true'];   % We usually want to equally seed both ROIs, so both flags = 'true'.
%      .roi2SeedFlag = ['true'];   % For speed you can choose not to seed the second ROI
%      .multiThread  = [0];        % Spawn many tracking jobs at once. 
%      .executeSh    = [0];        % Execute the script on cuurent host immediately using an xterm.
% 
% EXAMPLE USUAGE:
%       ctrParams          = ctrInitBatchParams;
%       ctrParams.baseDir  = '/Directory/Containing/Data';
%       ctrParams.dtDir    = 'dti40trilin';
%       ctrParams.roiDir   = 'ROIs'; % Relative to the subject dir. Contains the ROIs
%       ctrParams.subs     = {'subDir1','subDir2'};
%       ctrParams.ROI1     = {'Roi1a','Roi1b'}; % assumes '.mat'
%       ctrParams.ROI2     = {'Roi2a','Roi2b'}; % assumes '.mat'
%       ctrParams.nSamples = 10000;
%       [cmd info] = ctrInitBatch(ctrParams);
% 
% WEB RESOURCES:
%       http://white.stanford.edu/newlm/index.php/ConTrack
%       mrvBrowseSVN('ctrInitBatchParams');
% 
% See Also:
%       ctrInitBatchTrack.m , ctrInitBatchScore.m
%       
% 
% (C) Stanford Vista, 8/2011 [lmp]
% 
% 
%% Initialize ctrParams struct
  
ctrParams = struct;

%% I. Set Naming and Directory Structure 
  
ctrParams.projectName = 'myConTrackProj';                                        
ctrParams.logName     = 'myConTrackLog';      
ctrParams.baseDir     = '';                      
ctrParams.dtDir       = '';
ctrParams.roiDir      = '';

%% II. Set Subjects and ROIs
 
ctrParams.subs = {}; 
ctrParams.roi1 = {};    
ctrParams.roi2 = {};

%% III. Set Algorithm Parameters
  
ctrParams.nSamples     = 50000;    
ctrParams.maxNodes     = 240;      
ctrParams.minNodes     = 10;       
ctrParams.stepSize     = 1;        
ctrParams.pddpdfFlag   = 0;        
ctrParams.wmFlag       = 0;        
ctrParams.roi1SeedFlag = 'true';   
ctrParams.roi2SeedFlag = 'true';   
ctrParams.multiThread  = 0;
ctrParams.executeSh    = 0;

%% Varargin

ctrParams = mrVarargin(ctrParams,varargin);

return
