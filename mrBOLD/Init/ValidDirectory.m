function valid = ValidDirectory(rootDir,rawDir)

% if ValidDirectory(rootDir,rawDir), ...
%
% Checks the input directory structure and returns TRUE if
% it is valid, FALSE otherwise.
%
% DBR, 3/99

valid = 0;

% Check rootDir
if ~exist(rootDir,'dir') return; end
% Check subdirectories:
dirS = dir(rootDir);
names = {dirS.name};
if length(strmatch('Inplane', names)) == 0; return; end
dirS1 = dir(fullfile(rootDir, 'Inplane'));
rNames = {dirS1.name};
if length(strmatch('Original', rNames)) == 0; return; end
dirS1 = dir(fullfile(rootDir, 'Inplane', 'Original'));
rNames = {dirS1.name};
if length(strmatch('TSeries', rNames)) == 0; return; end

% Check rawDir
if ~exist(rawDir,'dir'); return; end
% Check subdirectories:
if ~exist(fullfile(rawDir,'Anatomy'),'dir')
    disp(['No Raw/Anatomy subdirectory found in: ',rawDir])
    return
end
if ~exist(fullfile(rawDir,'Pfiles'),'dir')
    disp(['No Raw/Pfiles subdirectory found in: ',rawDir])
    return
end

valid = 1;

  
