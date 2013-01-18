function [cmd infoFile] = ctrInitBatchTrack(ctrParams)
%  function [cmd infoFile] = ctrInitBatchTrack(ctrParams)
%
% OVERVIEW
%       This script takes functions from ctrInit and makes the sampler.txt
%       and .sh files (used by conTrack to generate fibers) for a large
%       group of subjects using as many pairs of ROIs as the user desires.
%
%       The logFile: Reports the results of the process as well as the
%       parameters used to setup the tracking script.
%
%       The infoFile: (info structure) Created for use with
%       ctr_conTrackBatchScore.m and saved in the log dir with the same
%       name as the log file.
%
%       What you end up with here is: (1) a log.mat file (for use with
%       ctr_conTrackBatchScore (path = infoFile), and (2) a .sh shell
%       script that will be displayed in the command window, which will run
%       tracking for all subjects and ROIs specified. The resulting .sh
%       file should be run on a 64-bit linux machine with plenty of power.
%
% USAGE NOTES:
%       The user should use ctrInitBatchParams to initialize the structure
%       that will contain all variables and algorithm params. see
%       ctrInitBatchParams.m - mrvBrowseSVN('ctrInitBatchParams');
%
%       After the script has completed the user will see instrucitons
%       appear in the command window telling the user to copy and paste a
%       provided line of code into their terminal in order to initiate
%       tracking. They will also see the full path to the log file that was
%       created by this script.
%
%       The directory in which the fibers will be saved is: subDir/fibers/conTrack/
%
% INPUTS:
%       ctrParams - a structure containing all variables needed to run this
%                   code. Get this struct by running 'ctrInitBatchParams'
%
% OUTPUTS:
%       cmd   - the command that can be run from your terminal to initiate
%               tracking. ** Why don't we allow the user to execute the
%               command through matlab??? Becuase it takes up matlab
%               licenses for the duration of the tracking - which is not
%               good.
%       infoFile  - Path to a file containing a struct with all parameters
%                   used for tracking. infoFile can be passed in to
%                   ctrBatchScore to initiate scoring.
%
% VARIABLES:  ** See ctrInitBatchParams to create these variables **
%       projectName = This variable will be used in the name of all the files
%                     that are created. E.g.,
%                     outFile = ['fg_',projectName,'_',roi1,'_',roi2,'_',timeStamp,'.pdb'];
%       logName     = This will be used to provide a unique name for easy ID in the log directory.
%       baseDir     = Top-level directory containing your data.
%                     The level below baseDir should have each subjects data directory.
%       dtDir       = This should be the name of the directory containing
%                     the dt6.mat file. E.g., dti40trilinrt.
%       logDir      = This directory will contain the log files for this project.
%       scrDir      = This directory will contain the .sh files used for tracking in linux.
%       subs        = This is the cell array that will contain the names
%                     of all the sujbect's directories that will be
%                     processed. ( e.g. subs = {'sub1','sub2','sub3'}; )
%                     NOTE: This script also supports the ability to load a
%                     list of subjects from a text file. If you wish to do
%                     this simply comment out the subs variable in section
%                     I or leave the cell empty. You will be prompted to
%                     select a text file that contains a list of subjects.
%                     Please assure that this list is a simple text file
%                     with only subject names seperated by new lines or
%                     spaces.
%       ROI1 & ROI2 = These two cell arrays should contain the names of
%                     each ROI to be used in tracking. The script will
%                     track from ROI1{1} to ROI2{1} and ROI1{2} to ROI2{2}
%                     etc... In case that you wish to track from
%                     multiple rois (ROI1) to the same roi (ROI2) you can
%                     just place the name of one roi in ROI2 and each roi
%                     in ROI1 will be tracked to the single roi in ROI2. **
%                     Code assumes '.mat' file extensions. - which you
%                     don't have to inlcude 
%                     E.g., ROI1 = {'Roi1a','Roi1b'}; ROI2 =
%                     {'Roi2a','Roi2b'};
%
% EXAMPLE USUAGE:
%       ctrParams          = ctrInitBatchParams;
%       ctrParams.baseDir  = '/Directory/Containing/Data';
%       ctrParams.dtDir    = 'dti40trilin';
%       ctrParams.subs     = {'subDir1','subDir2'};
%       ctrParams.roi1     = {'Roi1a','Roi1b'}; 
%       ctrParams.roi2     = {'Roi2a','Roi2b'}; 
%       ctrParams.nSamples = 10000;
% 
%       [cmd infoFile] = ctrInitBatchTrack(ctrParams);
%
% WEB RESOURCES:
%       http://white.stanford.edu/newlm/index.php/ConTrack
%       mrvBrowseSVN('ctrInitBatchTrack');
%       mrvBrowseSVN('ctrInitBatchParams');
% 
% SEE ALSO:
%       ctrInitBatchParams
%
% HISTORY:
%       2011  LMP adapted the code from ctrBatchCreateContrackFiles.m
%             and fundamentally changed the code - now it gets
%             ctrParams from ctrInitBatchParams. This code now does
%             not need to be edited by the user. One day I'll rewrite
%             the whole thing - it could be better...
%
% (C) Stanford Vista, 2011 [lmp]
%

%%  Check for params. If any of the key params are missing prompt for them

% Parameters
if notDefined('ctrParams') 
    doc('ctrInitBatchParams')
    error('You must run ctrInitBarchParams to set tracking parameters.');
end

% Subjects array
if isempty(ctrParams.subs) || numel(ctrParams.subs) == 0 
    [subFile filePath] = uigetfile('*.txt','Select text file containing a list of subjects.');
    if filePath == 0, disp('Canceled.'); return; end 
    subFile            = [filePath subFile];
    subs               = textread(subFile,'%s');
elseif exist('ctrParams.subs','file')
    % If the subs variable contans the path to a file containing sub names
    % we read it in here.
    subs = textread(ctrParams.subs,'%s');
else 
    subs = ctrParams.subs;
end

% Base directory
if isempty(ctrParams.baseDir) || ~exist(ctrParams.baseDir,'dir')
    ctrParams.baseDir = uigetdir(pwd, 'SELECT BASE DIRECTORY.');
    if ctrParams.baseDir == 0, disp('Canceled.'); return; end 
end

% DT6 Directory
if isempty(ctrParams.dtDir)
    ctrParams.dtDir = uigetdir(ctrParams.baseDir,'SELECT THE DT6 DIRECTORY');
    if ctrParams.dtDir == 0, disp('Canceled.'); return; end 
    [~, ctrParams.dtDir e] = fileparts(ctrParams.dtDir); %#ok<NASGU>
end

% ROI directory
if isempty(ctrParams.roiDir)
    ctrParams.roiDir = uigetdir(ctrParams.baseDir,'SELECT THE ROIs DIRECTORY');
    if ctrParams.roiDir == 0, disp('Canceled.'); return; end 
    [~, ctrParams.roiDir e] = fileparts(ctrParams.roiDir); %#ok<NASGU>
end

% ROI 1
if isempty(ctrParams.roi1)
    cd(ctrParams.baseDir);
    ctrParams.roi1 = {};
    ctrParams.roi1 = uigetfile('*.mat','ROI1: SELECT ROI1 ROIS (MIND THE ORDER)','MultiSelect','on');
    disp(['ROI1 = ' ctrParams.roi1]);
    if isnumeric(ctrParams.roi1), disp('Canceled.'); return; end 
end

% ROI 2
if isempty(ctrParams.roi2)
    cd(ctrParams.baseDir);
    ctrParams.roi2 = {};
    ctrParams.roi2 = uigetfile('*.mat','ROI2: SELECT ROI2 ROIS (MIND THE ORDER)','MultiSelect','on');
    disp(['ROI2 = ' ctrParams.roi2]);
   if isnumeric(ctrParams.roi2), disp('Canceled.'); return; end
end

if ~iscellstr(ctrParams.roi1)
    tmp = {};
    tmp{1} = ctrParams.roi1;
    ctrParams.roi1 = tmp;
end

if ~iscellstr(ctrParams.roi2)
    tmp = {};
    tmp{1} = ctrParams.roi2;
    ctrParams.roi2 = tmp;
end

% Check that the arrangement of ROI structures is valid
if numel(ctrParams.roi2)>1 && (numel(ctrParams.roi1) ~= numel(ctrParams.roi2))
    error('Unequal number of ROIs.');
end


%% Set up ROIs

% Check for and strip the file extensions if they are there
for i = 1:numel(ctrParams.roi1)
    [~, name e] = fileparts(ctrParams.roi1{i});
    if ~isempty(e); ctrParams.roi1{i} = name; end
end
for i = 1:numel(ctrParams.roi2)
    [~, name e] = fileparts(ctrParams.roi2{i});
    if ~isempty(e); ctrParams.roi2{i} = name; end
end


%% Create log and batchScript files
 
% Create log directory and scripts directory
logDir = fullfile(ctrParams.baseDir,'ConTrack', ctrParams.projectName,'logs');
scrDir = fullfile(ctrParams.baseDir,'ConTrack', ctrParams.projectName,'shellScripts');

if ~exist(logDir,'file'), mkdir(logDir); disp('Created Log Directory'); end
if ~exist(scrDir,'file'), mkdir(scrDir); disp('Created Shell Script Directory'); end

% Set the log file name using the project name and open the file for
% writing.
dateAndTime = getDateAndTime;
logFileName = fullfile(logDir,[ctrParams.projectName,'_',ctrParams.logName, '_ctrInitLog_', dateAndTime]);
logFile     = [logFileName, '.txt'];
fid         = fopen(logFile,'w');

% Set the time once for the whole script
timeStamp   = datestr(now,30);
timeStamp(strfind(timeStamp,'T')) = '_';
timeStamp = [timeStamp(1:4) '-' timeStamp(5:6) '-' timeStamp(7:11) '.' ...
             timeStamp(12:13) '.' timeStamp(14:15)];


%% Start writing the batch File that will run all resulting .sh files
 
batchFileName = fullfile(scrDir,[ctrParams.logName, '_ctrInitBatchTrack_', dateAndTime '.sh']);
fid2          = fopen(batchFileName, 'w');

fprintf(fid2, '\n#!/bin/bash');
fprintf(fid2, '\n# Log file used: %s \n', logFile);


%% Create info file that will be loaded for scoring - Saved with the
% same name as log file
 
info             = struct;
info.projectName = ctrParams.projectName;
info.baseDir     = ctrParams.baseDir;
info.subs        = subs;
info.dtDir       = ctrParams.dtDir;
info.roi1        = ctrParams.roi1;
info.roi2        = ctrParams.roi2;
info.logDir      = logDir;
info.scrDir      = scrDir;
info.timeStamp   = timeStamp;
info.nSamples    = ctrParams.nSamples;   %#ok<STRNU>

% Return and save infoFile
infoFile = [logFileName,'.mat']; save(infoFile,'info');


%% Log/Info Files: Print params to log and info files
 
fprintf(fid,'Info File: \n %s\n',infoFile);
fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'\nWill make conTrack files for %d subjects: \n',numel(subs));
fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'ctrInit Parameters:\n\n');
fprintf(fid,'\t Number of Samples: %d\n',ctrParams.nSamples);
fprintf(fid,'\t Max Nodes: %d\n',ctrParams.maxNodes);
fprintf(fid,'\t Min Nodes: %d\n',ctrParams.minNodes);
fprintf(fid,'\t Step Size: %d\n',ctrParams.stepSize);
fprintf(fid,'\t PDDPDF Flag (1=Always Compute): %d\n',ctrParams.pddpdfFlag);
fprintf(fid,'\t WM Flag (1=Always Compute): %d\n',ctrParams.wmFlag);
fprintf(fid,'\t ROI 1 Seed Flag (1=Seed ROI): %s\n',ctrParams.roi1SeedFlag);
fprintf(fid,'\t ROI 2 Seed Flag (1=Seed ROI): %s\n\n',ctrParams.roi2SeedFlag);
fprintf(fid,'\n ------------------------------------------ \n');
fprintf('\nWill make conTrack files for %d subjects. \n\n',numel(subs));


%% Create the ctrSampler and .sh files
 
for ii=1:numel(subs)
    fprintf(fid,'\n ------------------------------------------ \n');
    fprintf(fid2,'\n');
    
    sub = dir(fullfile(ctrParams.baseDir,[subs{ii} '*']));
    if ~isempty(sub)
        subDir = fullfile(ctrParams.baseDir,sub.name);
        dt6Dir = fullfile(subDir,ctrParams.dtDir);
        dt6    = fullfile(dt6Dir,'dt6.mat');

        % Check for pddDispersion file. 
        if ~exist(fullfile(dt6Dir,'bin','pddDispersion.nii.gz'),'file')
            error(['Contrack requires a pddDispersion.nii.gz file to be run. ' ...
                    'This file was not found. To genreate this file ' ... 
                      'you must boostrap during preprocessing']);
        end
                
        % ROIs directory for subject ii
        rDir   = fullfile(subDir,ctrParams.roiDir);
        
        % If the roi directory does not exist we prompt the user for it and
        % try to reset ctrParams.roiDir just in case there was an error in
        % typing when it was passed in.
        if ~exist(rDir,'dir');  
            rDir = uigetdir(subDir,'Select ROIs directory');
            [~, ctrParams.roiDir e] = fileparts(rDir); %#ok<NASGU>
            fprintf('Set roi directory to %s...\n', rDir);
        end
        
        % This is where the fibers will be saved. 
        fiberDir = fullfile(dt6Dir,'fibers','conTrack',ctrParams.projectName);
        if ~exist(fiberDir,'file'), mkdir(fiberDir); disp(['Created fiber directory >> ' fiberDir]); end
        
        % Loop over the ROIs and make the pairs. 
        for kk = 1:numel(ctrParams.roi1)
            roi1 = fullfile(rDir, [ctrParams.roi1{kk},'.mat']);
            % If there is only one entry in ctrParams.roi2 then that will
            % be the ROI that is used for each entry in ctrParams.roi1. 
            if numel(ctrParams.roi2) == 1
                roi2  = fullfile(rDir, [ctrParams.roi2{:},'.mat']);
                fname = [ctrParams.roi1{kk}, '_', ctrParams.roi2{:}];
            else
                roi2  = fullfile(rDir, [ctrParams.roi2{kk},'.mat']);
                fname = [ctrParams.roi1{kk}, '_', ctrParams.roi2{kk}];
            end
            
            % Make the params struct that will be passed to ctrInitParamsFile
            params.roi1File     = roi1;
            params.roi2File     = roi2;
            params.dt6File      = dt6;
            params.dSamples     = ctrParams.nSamples;
            params.maxNodes     = ctrParams.maxNodes;
            params.minNodes     = ctrParams.minNodes;
            params.stepSize     = ctrParams.stepSize;
            params.pddpdf       = ctrParams.pddpdfFlag;
            params.wm           = ctrParams.wmFlag;
            params.seedRoi1     = ctrParams.roi1SeedFlag;
            params.seedRoi2     = ctrParams.roi2SeedFlag;
            params.timeStamp    = timeStamp;
            
            % Fields printed to log file
            fprintf('\nProcessing %s... \n',sub.name);
            fprintf(fid,'\nProcessing %s... \n',sub.name);
            fprintf(fid,'\t dt6 File: %s\n',dt6);
            fprintf(fid,'\t ROI pair: %s\n',fname);
            fprintf(fid,'\t\t ROI 1: %s\n',roi1);
            fprintf(fid,'\t\t ROI 2: %s\n',roi2);
            
            % This does ALMOST EVERYTHING
            samplerName = ['ctrSampler_',ctrParams.projectName,'_',fname,'_',timeStamp,'.txt'];
            samplerName = fullfile(fiberDir,samplerName);
            
            params = ctrInitParamsFile(params,samplerName);
            fprintf(fid,'\t ctr.txt: %s\n',samplerName);
            
            bashName = ['ctrScript_',ctrParams.projectName,'_',fname,'_',timeStamp,'.sh'];
            bashName = fullfile(fiberDir,bashName);
            
            % Strip the extension and path from the ROI file names
            [~,roi1] = fileparts(params.roi1File);
            [~,roi2] = fileparts(params.roi2File);
            
            % Set the name for the superSet of fibers.
            outFile = ['fg_',ctrParams.projectName,'_',roi1,'_',roi2,'_',timeStamp,'.pdb'];
            
            % Creates the .sh file
            ctrScript(params,bashName,outFile);
            
            fprintf(fid,'\t ctr.sh: %s\n',bashName);
            
            % Writes the command to the batchShFilebatchFileName
            % Change to the conTrack dir before running the .sh.
            fprintf(fid2,'\n\ncd %s',fiberDir);
            
            % MultiThread option. If selected each shell script will be run
            % at the same time. Else it's run serially. 
            if ctrParams.multiThread == 1
                fprintf(fid2, '\n%s &', bashName);
            else
                fprintf(fid2, '\n%s', bashName);
            end
        end
    else
        fprintf(['\n No data for ' subs{ii} '! Skipping. \n']);
        fprintf(fid,'\n No data for %s. Skipping!\n', subs{ii});
    end
end


%% Save the log file and shell script
 
fprintf(fid,'\n --------------------------------- \n\n Script Completed.');

% Close out the log files
fclose(fid); 
fclose(fid2);


%% Edit permissions of the .sh file (batchFileName) 

[status,~] = system(['chmod 775 ' batchFileName]);
if status ~= 0
    disp(['chmod failure. Permissions need to be edited manually for ' batchFileName]);
end


%% Display and/or execute the shell script 

cd(scrDir);
fprintf('\n...\nLog file created: \n %s \n', logFileName);

% If the user want's to execute the tracking on this host then launch an
% xterm and do the tracking immediately. Or just display the cmd in the
% command window that can be copied and pasted in a terminal to run all of
% the .sh files.
if ctrParams.executeSh == 1
    fprintf('Submitting %s to xterm...\n', batchFileName);
    executeCmd = ['xterm -e ' batchFileName '&'];
    status = system(executeCmd);
    if status ~= 0
        fprintf('Something went wrong...');
        fprintf('\n...\nRun the following line of code in your terminal: \n. %s \n', batchFileName);
    end
else
    fprintf('\n...\nRun the following line of code in your terminal: \n. %s \n', batchFileName);
end

% Return the shell script command
cmd = batchFileName;

return
