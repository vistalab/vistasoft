function ok = autoinorm(useFMC,cleanup);
% ok = autoinorm(useFMC,cleanup);
%
% Calls FS-FAST function inorm (which performs intensity normalization),
% converting Pmags to Bshorts if necessary, and converts the resulting
% Bshorts back to Pmags with sensible file names.
%
% useFMC: use functional motion-corrected data.
%
% cleanup: delete bshorts when done (if set to 1, defaults to 0, leave
% files).
%
% 06/03 ras
if ~exist('cleanup','var')  cleanup = 0;    end
if ~exist('useFMC','var')   useFMC = 0;     end

ok = 0;

% check we're running on a unix system, or we can't call FS-FAST.
if ~isunix
  fprintf('*******************************************\n');
  fprintf('Sorry, you''re not running on a unix machine.\n');
  fprintf('This needs to be run on a unix machine (e.g., moach).\n');
  fprintf('*******************************************\n');
  return
end

mrGlobals;
loadSession;
HOMEDIR = pwd;        

nScans = length(dataTYPES(1).scanParams);

%%%%% create 'mc' functional subdirectory, if necessary
PmagDir = fullfile(HOMEDIR,'Raw','Pfiles');
fsDir = fullfile(HOMEDIR,'mc');
if ~exist(fsDir)
    cd(HOMEDIR);
    mkdir('mc');
    fprintf('Creating directory %s.\n',fsDir);
end

%%%%% convert Pmags to bshorts, if necessary
if ~exist(fullfile(fsDir,getFsIndex(nScans)),'dir')
    pmag2bsh(PmagDir,fsDir);
end

%%%%% call FS-FAST motion correction routine (inorm-sess)
dirS = mc_GetDirectory(HOMEDIR);
[sesspar,sessdir] = fileparts(dirS.home);
if useFMC
    funcstem = 'fmc';
else
    funcstem = 'f';
end
cmd = ['inorm-sess -s ' sessdir ' -d ' sesspar ' -fsd mc -funcstem ' funcstem];
cd(fsDir);
unix(cmd);

cd(HOMEDIR);

%%%%% convert bshorts to Pmags
for scan = 1:nScans
    bshortDir = fullfile(fsDir,getFsIndex(scan))
    pFileName = ['mc_norm_Scan' num2str(scan) '.7.mag'];
    bsh2pmag(bshortDir,fsDir,funcstem,pFileName);
end

%%%%% cleanup bshorts if selected
if cleanup
    cd(fsDir);
    w = filterdir('0',pwd);
    for i = 1:length(w)
        if w(i).isdir
            mcdatfile = fullfile(fsDir,w(i).name,'fmc.mcdat');
            if exist(mcdatfile,'file')
                cmd = ['cp ' mcdatfile ' ./Scan' num2str(i) '.mcdat'];
                unix(cmd);
            end
            
            cmd = ['rm -R ' w(i).name];
            unix(cmd);
        end
    end
end

cd(HOMEDIR);

ok = 1;    

return