function ok = automc(view,cleanup,convertBack);
% ok = automc(view,[cleanup,convertBack]);
% 
% Perform AFNI motion correction using FS-FAST
% 
% cleanup: flag to delete bshorts when finished. if 1, will delete bshorts.
%
% convertBack: convert motion-corrected bshorts back to tSeries in 
% the 'MotionCorrected' data type. Set to 0 to skip
% this step.
%
% ras, 6/03
global dataTYPES mrSESSION HOMEDIR;
if ~exist('cleanup','var')      cleanup = 1;            end
if ~exist('convertBack','var')  convertBack = 1;        end

if ieNotDefined('view')
    mrGlobals;
    loadSession;
    view = initHiddenInplane;
    HOMEDIR = pwd;
end

ok = 0;

% check we're running on a unix system, or we can't call FS-FAST.
if ~isunix
  fprintf('*******************************************\n');
  fprintf('Sorry, you''re not running on a unix machine.');
  fprintf('This needs to be run on a unix machine (e.g., moach).\n');
  fprintf('*******************************************\n');
  return
end

nScans = length(dataTYPES(1).scanParams);

% if > 1 scans, set the target run as the 2nd -- the subjects
% tend to move during the first (feel free to change this param)
if nScans > 1
    targetRun = 2;
end

%%%%% create 'mcTempFiles' functional subdirectory, if necessary
PmagDir = fullfile(HOMEDIR,'Raw','Pfiles');
fsd = 'mcTempFiles';
fsPath = fullfile(HOMEDIR,fsd);
if ~exist(fsPath)
    cd(HOMEDIR);
    cmd = sprintf('mkdir %s',fsd);
    fprintf('Creating directory %s.\n',fsPath);
    unix(cmd)
end

%%%%% convert Pmags to bshorts, if necessary
if ~exist(fullfile(fsPath,sprintf('%03d',nScans)),'dir')
    fprintf('Converting tSeries to temporary intermediate format...\n');
    convertPmagToBshort(PmagDir,fsPath,mrSESSION);
end

%%%%% make a command file to call FS-FAST motion
%%%%% correction routine (mc-sess)
[sesspar,sessdir] = fileparts(HOMEDIR);
cmdFile = fullfile(fsPath,'afniMcRunme');
fid = fopen(cmdFile,'w');
fsPath = '/biac1/kgs/sns/biox/linux/freesurfer_alpha';
cmd = sprintf('set FREESURFER_HOME=%s',fsPath);
fprintf(fid,'%s\n',cmd);
cmd = 'source $FREESURFER_HOME/FreeSurferEnv.csh';
fprintf(fid,'%s\n',cmd);
cmd = sprintf('mc-sess -targnthrun %i -s %s -d %s -fsd %s',targetRun,sessdir,sesspar,fsd);
fprintf(fid,'%s\n',cmd);
fclose(fid);
% set execute permissions
cmd = sprintf('chmod 775 %s',cmdFile);
unix(cmd);

%%%%% run the command -- do the motion-correction
cd(HOMEDIR);
fprintf('\n\n\n\t***** Motion-Correcting *****\n\n\n');
cmd = sprintf('csh %s',cmdFile);
unix(cmd);

%%%%% convert bshorts to Pmags
if convertBack
    mc_fmc2TSeries(view,fsd);
end

% %%%%% copy over E-files from Raw/Pfiles/ directory
% cd(HOMEDIR);
% w = filterdir('E',PmagDir);
% for i = 1:length(w)
%   fname = fullfile(PmagDir,w(i).name);
%   cmd = ['cp ' fname ' mcTempFiles/EScan' num2str(i) '.7'];
%   unix(cmd);
% end

%%%%% cleanup bshorts if selected (save fmc.mcdat files)
if cleanup
    fprintf('\n\n\n***** CLEANING UP INTERMEDIATE FILES *****\n\n\n');
    ok = mc_cleanupBshorts(HOMEDIR,fsd);
    if ok==1
        % the motion-correction results were backed up ok
        cmd = sprintf('rm -R %s',fsd);
        unix(cmd);
    end
end

cd(HOMEDIR);

ok = 1;    

return
