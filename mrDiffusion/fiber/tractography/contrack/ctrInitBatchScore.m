function batchFileName = ctrInitBatchScore(infoFile, numPathsToScore, multiThread, executeScript)
 
% batchFileName = ctrInitBatchScore([infoFile = uigetfile], ...
%       [numPathsToScore = '1000'], [multiThread=0], [executeScript = 0]);
%
% This function allows the user to score multiple conTrack fiber sets
% across subjects. The user must point to an infoFile that was created with
% ctrInitBatchTrack.m. That script will place all relevant data into a
% structure which this function will read in. 
%
% We save out the top numpathstoscore from the original fiber group. This
% is the --thresh and --sort option in contrack_score.glxa64. See
% http://white.stanford.edu/newlm/index.php/ConTrack#Score_paths for more
% info. 
% 
% INPUTS:
%   infoFile      - Created by ctrInitBatchTrack. Contains all relevant
%                   data
%                   in a struct that is read here. If the user does not
%                   pass define this variable then the gui flag is tripped
%                   and they are prompted for the info file and the other
%                   variables as well. 
%   numPaths...   - Number of paths to score.
%   multiThread   - If multiThread == 1 all scoring commands will be executed
%                   in parallel.
%   executeScript - If executeScript==1 (default=0) then a terminal will be
%                   launched and the batch script will be run immediately
%                   on this machine. If == 0 then the script location will
%                   be thrown to the command window and the user can
%                   execute it where he/she pleases. 
% 
% OUTPUTS:
%   batchFileName - Name of the shell script that is run to do the
%                   scoring.
% 
% WEB RESOURCES:
%   mrvBrowseSVN('ctrInitBatchScore');
%   http://white.stanford.edu/newlm/index.php/ConTrack
%
% 
% (C) Stanford University, VISTA LAB 2011 [lmp]
% 

%% Check INPUTS and set DEFAULTS

if notDefined('infoFile')
    gui = 1;
    [f, p]   = uigetfile({'*.mat';'*.*'}, 'Please choose a Log.mat file', pwd);
    infoFile = fullfile(p,f);
else
    gui = 0;
end

if notDefined('numPathsToScore')
    numPathsToScore = 1000;
end

if notDefined('multiThread');
    multiThread = 0;
end

if notDefined('executeScript');
    executeScript = 0;
end

% Default file out type = .pdb
fileType = '.pdb';

%% Load the .MAT file created by ctrBatchCreateContrackFiles
 
load(infoFile);
% Parse the info structure
projectName = info.projectName;
batchDir    = info.baseDir;
subs        = info.subs;
dtDir       = info.dtDir;
ROI1        = info.roi1;
ROI2        = info.roi2;
scrDir      = info.scrDir;
timeStamp   = info.timeStamp;
nSamples    = info.nSamples;
nSamples    = num2str(nSamples);

    
%% Set-up other Input Variables using the input dialoge box

% Launch the dialog box and prompt the user for the other input
% variables. This will only happen if notDefined('logfile').
if gui
    % Get the hostname for this machine
    [st host] = system('hostname'); 
    if st ~= 0, host = 'this machine?'; end
    prompt = {['Please enter the number of paths you would like scored [out of ' num2str(nSamples) ']:'],...
               'Would you like to score all subjects at once (using multiple cores)? 0 (NO) or 1 (YES): ',...
               ['Run algorithm on ' host '0 (NO) or 1 (YES):']};
    dlg_title           = 'Input for ConTrack Batch Scoring';
    num_lines           = 1;
    defaultanswer       = {'1000','0','0'};
    options.Resize      = 'on';
    options.WindowStyle = 'normal';
    options.Interpreter = 'tex';

    scoreInputs     = inputdlg(prompt, dlg_title, num_lines, defaultanswer, options);
    numPathsToScore = scoreInputs{1};
    multiThread     = str2double(scoreInputs{2});
    executeScript   = str2double(scoreInputs{3});
    
    % Make sure the user entered something...
    if isempty(numPathsToScore), error('Number of paths to score not valid.'); end
    if isempty(multiThread),     error('Multi-thread option not specified.'); end
    if isempty(executeScript),   error('Execute script option not specified.'); end
end

% Make numPathsToScore a string that can be used to make the eval call
if ~ischar(numPathsToScore)
    numPathsToScore = num2str(numPathsToScore); 
end


%% Build up the struct with the ROI pairs. We need the names of these ROI
% pairs to sort the .sh scripts later on.

cd(batchDir);
roiPair = {};

for ff=1:length(ROI1)
    if numel(ROI2) == 1
        fname = [ROI1{ff}, '_', ROI2{:}];
    else
        fname = [ROI1{ff}, '_', ROI2{ff}];
    end
    roiPair{ff} = fname; %#ok<AGROW>
end


%%  Create a name for the batch .sh file.
 
dateAndTime   = getDateAndTime;
batchFileName = fullfile(scrDir,[projectName,'_ctrBatchScore_',dateAndTime,'.sh']);

fid = fopen(batchFileName, 'w');
fprintf(fid, '\n#!/bin/bash');
fprintf(fid, '\n# Log file used: %s \n',infoFile);

% Build/set arguments for contrack_score.glxa64 command.
if ismac
    ctrScore = 'contrack_score.maci64';
else % assume linux
    ctrScore = 'contrack_score.glxa64';
end
thresh = [' --thresh ', numPathsToScore, ' --sort '];


%% Loop over subjects and create the scoring shell script
 
for ii=1:length(subs)
    sub      = dir(fullfile(batchDir,[subs{ii} '*']));
    subDir   = fullfile(batchDir,sub.name);
    fiberDir = fullfile(subDir,dtDir,'fibers','conTrack',projectName);
    
    % For each roiPair find the associated .sh file. There are many .sh
    % files (potentially)
    for kk=1:numel(roiPair)
        fgOutName = ['scoredFG_',projectName,'_',roiPair{kk},'_top',numPathsToScore];
        fgout = [fgOutName, fileType];
        
        cd(fiberDir);
        
        % Get the names of the individual shell scripts.
        theSHfile = dir(['*',roiPair{kk},'*',timeStamp,'.sh']);
        theSHfile = theSHfile.name;
        fid2      = fopen(theSHfile);
        tmp       = fgetl(fid2); %#ok<NASGU>
        line      = fgetl(fid2);
        
        % Build the individual commands
        [ctrSampler, fginName] = getInfoFromShFile(line);
        fclose(fid2);
        theCD   = ['cd ' fiberDir];
        fprintf(fid, '\n%s', theCD);
        theCmd  = [ctrScore, ' -i ', ctrSampler, ' -p ', fgout, thresh, fginName];
        
        % Multi thread. If the user selected this option then we set "&" at
        % the end of every command so that the next command is run
        % in parallel. 
        if multiThread == 1
            fprintf(fid, '\n%s &\n', theCmd);
        else
            fprintf(fid, '\n%s\n', theCmd);
        end
    end
end

%% Save the batch shell script file and edit permissions

fclose(fid); 

% Edit permissions of the .sh file (batchFileName) so that it can be executed.
[status,result] = system(['chmod 775 ' batchFileName]); %#ok<NASGU>
if status ~= 0
    disp(['chmod failure in ctrBatchScore.m line 129: Permissions need to be edited manually for ' batchFileName]);
end


%% Display the command in the command window that can be copied and pasted
% in a terminal to run all of the .sh files. If the user selected execute
% script on this host then open a terminal and execute the script. 

cd(scrDir);

if executeScript == 1
    executeCmd = ['xterm -e ' batchFileName '&'];
    status = system(executeCmd);
    if status ~= 0
        fprintf('Something went wrong...');
        fprintf('Copy and paste the following line of code into your shell to batch score: \n. %s \n ', batchFileName);
    end
else
    fprintf('Copy and paste the following line of code into your shell to batch score: \n. %s \n ', batchFileName);
end

return





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ctrSampler, fginName] = getInfoFromShFile(line)
% This is a hacky way of parsing the sampler text file and returning what
% we need from it. There is no doubt a better way to do this. 
spaces      = strfind(line,' ');
c           = 1; % Counter
allWords    = {};

for jj=1:length(spaces)
    theWord         = line(c:spaces(jj));
    allWords{jj}    = theWord; %#ok<AGROW>
    c               = spaces(jj)+1;
end

theTxt      = strmatch('-i', allWords)+1;
theFg       = strmatch('-p', allWords)+1;
ctrSampler  = allWords{theTxt};
% leave off the ' mark and space.
fginName    = allWords{theFg}(1:end-2); 

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




    