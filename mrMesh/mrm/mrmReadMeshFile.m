function [msh, meshDir] = mrmReadMeshFile(filename)
%Read a 3D msh file (*.mat) for rendering the cortical surface
%
%   [msh, meshDir] = mrmReadMeshFile([filename])
%
% Read a msh file (*.mat). If the filename is not specified or doesn't
% exist, the user is prompted.  The msh filename is returned in
% msh.fileName.  The msh.id is set to -1.
%
% The second output argument is the path to the directory containing
% the mesh.
%
% Author: RFD
% ras, 02/2007 -- allows a directory to be given as the filename, for a
% start directory (e.g., mesh directory for a given hemisphere).
global vANATOMYPATH


% Define mesh so that even if we fail it will be returned (though empty).
msh = [];
meshDir = [];

if notDefined('filename')

    curDir = pwd;
    if notDefined('vANATOMYPATH')
        % stay in this directory
    else
        [p,n] = fileparts(vANATOMYPATH);
        chdir(p);        
    end

    filename = '';
    [f,p] = uigetfile({'*.mat';'*.*'}, 'Select a mesh file');
    chdir(curDir);

    if(isnumeric(f)) msh = []; return; end
    filename = fullfile(p,f);
    
elseif exist(filename, 'dir')
    % if directory specified, use this as a start directory
    filename = mrvSelectFile('r', {'*.mat';'*.*'}, 'Select a mesh file', filename);    
    if isempty(filename), msh = []; return; end % exit gracefully
    
end

% if filename not found, check for .mat extension
if ~exist(filename, 'file')
    if exist([filename '.mat'], 'file')
        filename = [filename '.mat'];
    end
end

if exist(filename,'file') == 7
    % The user sent in a directory, not a file
    dirName = filename;
    curDir = pwd; chdir(dirName);
    [f,p] = uigetfile({'*.mat';'*Mesh.*'}, 'Read mesh file');
    chdir(curDir);

    if(isnumeric(f)) msh = []; return; end
    filename = fullfile(p,f);

end

% Shouldn't be necessary, but ... maybe it doesn't exist
if ~exist(filename,'file'); 
	warning('Mesh file %s not found. Returning empty mesh...', ...
			filename);
	msh = []; 
	return; 
end

% Load the file.
load(filename);
msh = meshFormat(msh);

% Sometimes the file is in the local directory.  The which() returns a full
% path to the filename.
[meshDir,f,ext] = fileparts(fullpath(filename));
f = [f ext];

% Add the file name and current mesh id (none) to the mesh structure
msh = meshSet(msh, 'path', fullfile(meshDir, f));
msh = meshSet(msh, 'filename', filename);
msh = meshSet(msh, 'windowid', -1);

return;