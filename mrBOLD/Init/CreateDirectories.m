function status = CreateDirectories(rootDir)
% status = CreateDirectories(rootDir);

% Set up the directory structure for reconning and subsequent use
% by mrLoadRet. Return TRUE if all directories are successfully
% created or already present.
%
% DBR, 4/99

status = 0;
% Create the root directory if it doesn't already exist:
if ~MakeDir(rootDir)
    disp(['Could not create home directory ',rootDir]);
    return
end

% Create the other directory structures if they don't already exist:
if ~MakeDir('Inplane', rootDir); return; end
if ~MakeDir('Original', fullfile(rootDir,'Inplane')); return; end
if ~MakeDir('TSeries', fullfile(rootDir,'Inplane','Original')); return; end

status = 1;

