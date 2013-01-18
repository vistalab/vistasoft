function mtrExecuteWinBash(cmd,workDir)

% mtrExecuteWinBash(cmd,workDir)

%% Create dir stack
oldDir = pwd;
cd(workDir);

%% Change cmd to remove '\' and replace with '/'
cmd(cmd == '\') = '/';

%% Create a script to run the cmd in the working directory
scriptFile = fullfile(workDir,'temp.sh');
fid = fopen(scriptFile,'wt');
fprintf(fid,'#!/bin/bash\n');
fprintf(fid,'%s; \n', cmd);
fclose(fid);

%% Run script
system(['bash ' scriptFile],'-echo');

%% Remove script
delete(scriptFile);

%% Back to original directory
cd(oldDir);

return;