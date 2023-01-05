function fmri_FFA_mrInit2preprocessScript(startDir,MCflag,MCframe)
% Usage:
% fmri_FFA_mrInit2preprocessScript([startDir=pwd],[MCflag=4],[MCframe=8]);
% fmri_FFA_mrInit2preprocessScript('/biac1/kgs/projects/Kids/fmri/local
% izers'); 
%
% This script will check all subjects in a particular directory (STARTDIR;
% if no input, defaults to pwd) and see if they are appropriate for mrInit2
% preprocessing. Please make sure to setup the Raw directory appropriately
% before starting the script!
%
% To be a candidate for preprocessing, the subject must have the following
% directory structure at subjDir/Raw level (watch spelling/caps!):
% (1) Anatomy
%       * 3pln
%       * Inplane
%       * SS
% (2) Pfiles
%       * all the subject's raw E.7, P.7/.hdr/.mag/.mot files 
%       * five of same-numbered files per functional scan
%
% The script runner will then have to manually enter in some information
% about each subject to be preprocessed (e.g,. their name, nFrames to
% discard, parfile, etc). So you might want to have the scansheet info in
% front of you for the first 5-10 of running this script. 
%
% By 2008/09/04: DY & AL
%
% TODO: Implement user prompts for retinotopy initialization parameters
% (ask GG), including way to document these scan-specific parameters in the
% logfile writing function (fmri_FFA_logParamsMrInit2)

% Check input arguments 
if(~exist('MCflag','var')||~isnumeric(MCflag)), MCflag= 4; end %Within then between
if(~exist('MCframe','var')||~isnumeric(MCframe)), MCframe= 8; end
if(~exist('startDir','var')||isdir(startDir)), startDir = pwd; end

% Create subject list (SUBS)
cd(startDir); s = dir('*0*');  subs={s.name};


startTime = clock;

% Set-up log file (define fid).
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logDir=fullfile(startDir,'logs');
if ~isdir(logDir), mkdir(logDir), end; 
logFile = fullfile(logDir,['Preprocess_Log_' dateAndTime '.txt']);
fid=fopen(logFile,'w');
[junk,logFileName]=fileparts(logFile)
scriptName = 'fmri_FFA_mrInit2preprocessScript.m';



% We check all subjects for the correct Raw Directory structure, and create
% a list of all appropriate subjects for mrInit2 preprocessing.
[n,doThese]=checkRawDirSetupMrInit2(subs,startDir,fid);

% If we don't find anyone, quit out of the function.
if n==0
    fprintf(fid,'\n FAILURE: didn''t find anyone suitable for preprocessing \n');
    fprintf('\n FAILURE: didn''t find anyone suitable for preprocessing  \n');
    return
end

% If we do find people to do (DOTHESE), proceed. 
for ii=1:length(doThese)
    cd(fullfile(startDir,doThese{ii}));
    
    % After running mrInitDefaultParams, the params struct should be
    % correctly initialized for the following fields (all other blank):
    %   inplane
    %   functionals
    %   sessionDir
    %   sessionCode
    params{ii} = mrInitDefaultParams;
    params{ii}.motionComp = MCflag;
    params{ii}.motionCompRefFrame=MCframe;
    
    % Request script user to manually enter in scan params info for each
    % subject that will be preprocessed. 
    %
    % Also present the user an option for what to do if they want to leave
    % that field blank.

    fprintf('\n Please enter information for session: %s\n',doThese{ii});
    params{ii}.subject = askP('\nSubject''s full name: ',[],true);
    params{ii}.description = askP('\nDescription of session: ',[],true);
    params{ii}.comments = askP('\nComments for session: ',[],true);
    params{ii}.motionCompRefScan=askP('\nRefScan # for between-scan motion correction: ',[1:1:length(params{ii}.functionals)]);

    % LOOP: ask questions specific to particular scans
    for jj=1:length(params{ii}.functionals)
        [junk,pfile]=fileparts(params{ii}.functionals{jj});
        fprintf('\n\n***** Now please enter information relevant to %s *****\n\n',pfile);
        params{ii}.annotations{jj}=askP('\nAnnotation (e.g, loloc_run1): ',[],true);
        params{ii}.parfile{jj}=askP('\nParfile (e.g., loloc_run1_030808_9c.par): ',[],true);
        
        % TO DO: retinotopy
        % keepFrames
        % coParams
        % applyCorAnal

    end
    fprintf('\nThanks! We are all done with session: %s',doThese{ii});
    fprintf('\nBy the way, we are doing within then between scan MC, within-scan base frame %d',MCframe);
    fprintf('\n-------------------------------------\n');

end

for ii=1:length(doThese)
    cd(fullfile(startDir,doThese{ii}));
    
    % Write parameters to logFile for this subject
    fmri_FFA_logParamsMrInit2(startDir,params{ii},doThese{ii},fid);
    
    try
        mrInit2(params{ii});
        fprintf('\n MrInit2: preprocessed subject %s successfully \n',doThese{ii});
        fprintf(fid,'\n MrInit2: preprocessed subject %s successfully \n',doThese{ii});
    catch
        % For some reason, stepping through this code causes the CATCH code
        % to be executed, even though mrInit2 runs successfully. Figure out
        % why this is... 
        fprintf(fid,'\n FAILURE TO SUCCESSFULLY RUN MRINIT2 PREPROCESS \n');
        fprintf('\n FAILURE TO SUCCESSFULLY RUN MRINIT2 PREPROCESS \n');
        theerror=lasterror;
        fprintf(fid,'%s \n\n',theerror.message);
        fprintf('%s \n\n',theerror.message);
    end
    
    subTime=etime(clock,startTime);
    fprintf(fid,'\nTotal running time for subject: %f minutes \n',subTime/60);
    fprintf('\nTotal running time for subject: %f minutes \n',subTime/60);

end

totalTime=etime(clock,startTime); 

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'Total running time for script: %f minutes \n',totalTime/60);
fprintf('Total running time for script: %f minutes \n',totalTime/60);
fclose(fid); % close out the log file

return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function answer=askP(question,answerkey,stringFlag)
% This will reask each question until the user inputs an acceptable answer
% (rather than quit out of whole script, or cause errors down the road). An
% acceptable answer is defined as being a member of the ANSWERKEY, unless
% stringFlag is set to true. If stringFlag is true, then an acceptable
% answer is any non-empty input. If there is no stringFlag input argument,
% it's default value is false. 

if(~exist('stringFlag','var'))
    stringFlag = false; 
end

switch stringFlag
    case true % expect non-empty string answers
        answer='';
        while isempty(answer)
            answer = input(question,'s');
        end
    case false % expect numerical/specially-formatted answers
        answer=0;
        while ~ismember(answerkey,answer)
            answer = input(question);
        end
end

return




                 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fmri_FFA_logParamsMrInit2(startDir,p,theSubject,fid)
% This will write all the parameters we set above to the log file for
% documentation purposes. 
%
% TODO: implement way to document retinotopy related parameters. 

% Start a log text file to document successes and failures in preprocessing


fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'\n MRINIT2 PARAMETERS FOR %s ', theSubject);
fprintf(fid,'\n ------------------------------------------ \n');

fprintf(fid,'General parameters \n\n');

fprintf(fid,'params.inplane: %s \n',p.inplane);

fprintf(fid,'params.vAnatomy: default(empty string) \n');
fprintf(fid,'params.sessionDir: %s \n',p.sessionDir);
fprintf(fid,'params.sessionCode: %s \n',p.sessionCode);
fprintf(fid,'params.subject: %s \n',p.subject);
fprintf(fid,'params.description: %s \n',p.description);
fprintf(fid,'params.comments: %s \n',p.comments);
fprintf(fid,'params.crop: default(empty matrix) \n');
fprintf(fid,'params.applyGlm: %d \n',p.applyGlm);
fprintf(fid,'params.motionComp: %d \n',p.motionComp);
fprintf(fid,'params.sliceTimingCorrection: %d \n',p.sliceTimingCorrection);
fprintf(fid,'params.motionCompRefScan: %d \n',p.motionCompRefScan);
fprintf(fid,'params.motionCompRefFrame: %d \n',p.motionCompRefFrame);

for ii=1:length(p.functionals)
    fprintf(fid,'\n Specific parameters for functional scan %d\n\n',ii);
    
    fprintf(fid,'params.functionals: %s \n',p.functionals{ii});
    % fprintf(fid,'params.keepFrames: %s \n',num2str(p.keepFrames(ii,:)));
    fprintf(fid,'params.annotations: %s \n',p.annotations{ii});
    fprintf(fid,'params.parfile: %s \n',p.parfile{ii});
    % fprintf(fid,'params.coParams: %s \n',p.coParams);
    fprintf(fid,'params.glmParams: default (empty, we assign parameters with our scripts!) \n');
    fprintf(fid,'params.scanGroups: default(empty matrices) \n');
    % fprintf(fid,'params.applyCorAnal: %s \n',p.applyCorAnal);

end

return