function ok = mc_cleanupBshorts(dirs,fsDir);
% ok = mc_cleanupBshorts([dirs],[fsDir]);
% 
% After motion-correcting with mc-sess (AFNI algorithm),
% clean up the bshorts directory. Defaults to
% 'bold' directory in current dir.
%
% This saves the text files with the 
% results of the motion correction, in the
% 'Inplane/mc' directory of each specified
% session directory. The motion files are 
% all tab-delimited ASCII text with the
% .mcdat extension: see showMeMotion
% for an explanation of each column.
%
% fsDir: functional subdirectory where
% bshorts are kept for each session. 
% Defaults to 'bold'.
%
% ras 08/04 from automc
if ieNotDefined('dirs')
    dirs = {pwd};
end

if ischar(dirs)
    dirs = {dirs};
end

if ieNotDefined('fsDir')
    fsDir = 'bold';
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
    
mrGlobals;
loadSession;
load mrSESSION;
 
HOMEDIR = pwd;        

                tgtdir = 'EstimatedMotion';

nScans = length(dataTYPES(1).scanParams);

%%%%% cleanup bshorts (save fmc.mcdat files)
for d = 1:length(dirs)
    cd(dirs{d});
    pattern = fullfile(fsDir,'0*');
    w = dir(pattern);
    fprintf('Deleting bshorts...\n');
    for i = 1:length(w)
        if w(i).isdir
            mcdatfile = fullfile(fsDir,w(i).name,'fmc.mcdat');
            if exist(mcdatfile,'file')
                % cmd = ['cp ' mcdatfile ' ./Scan' num2str(i) '.mcdat'];
                if ~exist(tgtdir,'dir')
                    mkdir(tgtdir);
                end
                tgtfile = fullfile(tgtdir,sprintf('Scan%i.mcdat',i));
                cmd = sprintf('cp %s %s',mcdatfile,tgtfile);
                unix(cmd);
            end
            
            % only remove the bshorts if the mcdatfiles were
            % actually successfully copied
            if exist(tgtfile,'file')
                cmd = ['rm -R ' fullfile(fsDir,w(i).name)];
                unix(cmd);
            else
               error('Couldn''t copy the mcdat files...');
            end
        end
    end

    fprintf('Done cleaning up bshorts for %s.\n',dirs{d}); 
    fprintf('Saved motion results in %s.\n',tgtdir);
end

fclose all

cd(HOMEDIR);

ok = 1;    

        % the motion-correction results were backed up ok
        cmd = sprintf('rm -R %s',fsDir);
        unix(cmd);
        cmd = sprintf('rm -R log');
        unix(cmd);

fprintf('All Done.\n');

return
