function fmri_FFA_eraseGLMdatatype

% Erase GLMs datatype for all scans in the localizer directory.
%
% This way, GLMs script can operate fresh and clean. We plan to only run
% this the once. 
%
% DY 06/05/2008

% Set directory and subject list
if ispc
    fmriDir = 'W:\projects\Kids\fmri\localizer\';
else
    fmriDir = '/biac1/kgs/projects/Kids/fmri/localizer/';
end
cd(fmriDir)
s=dir('*0*'); subs={s.name};

% Start a log text file to document successes and failures in preprocessing
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logFile = fullfile(fmriDir,'logs',['GLMerase_log_' dateAndTime '.txt']);
fid=fopen(logFile,'w');
[junk,logFileName]=fileparts(logFile)
startTime = clock;

for ii=1:length(subs)

    thisDir = fullfile(fmriDir,subs{ii}); cd(thisDir);
    fprintf(fid,'Processing %s\n',thisDir);
    fprintf('Processing %s\n',thisDir);

    % Erase GLMs datatype all scans
    load mrSESSION.mat
    removeDataType('GLMs', false);
    save(fullfile(thisDir,'mrSESSION.mat'),'mrSESSION','dataTYPES', '-append');
    fprintf(fid,'Removed GLM datatype \n\n');
    fprintf('Removed GLM datatype \n\n');
     clear dataTYPES mrSESSION vANATOMYPATH HOMEDIR
end

totalTime=etime(clock,startTime); 

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'Total running time for script: %f minutes \n',totalTime/60);
fprintf('Total running time for script: %f minutes \n',totalTime/60);

fclose(fid); % close out the log file


return

