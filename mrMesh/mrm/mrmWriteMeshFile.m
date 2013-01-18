function [msh, savePath] = mrmWriteMeshFile(msh, filename, verbose)
%Write mesh to a file in the subject's anatomy directory.
%
%       [msh, savePath] = mrmWriteMeshFile(msh, [filename], [verbose=1])
%
% The fileName (full path) field of the mesh is updated to reflect the new
% file name (empty if user cancels).  
%
% ras, 11/05 -- added mesh.path field.
% bw,  02/06 -- program checked that the filename exists.  But if we are
%               writing out a file, the file shouldn't have to exist. So I
%               deleted that test.
% Example:
%   
%
% (c) Stanford, mrVista team

if notDefined('msh'), error('Mesh required.'); end

savePath = '';

if notDefined('verbose'), verbose = 1; end

if notDefined('filename')
    % No name sent in.  So we get one.
    try, startDir = getAnatomyPath; catch, startDir = pwd; end
    filename = mrvSelectFile('w','mat','Save Mesh',startDir);
    if  isempty(filename), disp('User canceled'); return; end
    p = fileparts(filename);
elseif exist(filename,'file') == 7
    % The user sent us a directory, not a file
    dirName = filename;
    curDir = pwd; chdir(dirName);
    [f,p] = uiputfile({'*.mat';'*Mesh.*'}, 'Save mesh file as');
    chdir(curDir); 
    if(isnumeric(f)) disp('Save canceled.'); return; end
    filename = fullfile(p,f);
    [p,n,e] = fileparts(filename);
    if ~strcmp(e,'.mat'), filename = [filename,'.mat']; end
else
    p = fileparts(filename);
end

savePath = p;

msh = meshSet(msh,'path',savePath);
msh = meshSet(msh,'filename',filename);

if (isfield(msh,'surface'))  % Added to save EMSE / FS /PIAL meshes
    if(strcmp(msh.surface,'pial'))
        disp('We are keeping the v2g map for now -ARW / SKERI');

    else
        msh = meshSet(msh,'vertex2graymap',[]);
    end
end

save(filename, 'msh');

if verbose, fprintf('Saving mesh in %s\n',filename); end

return;