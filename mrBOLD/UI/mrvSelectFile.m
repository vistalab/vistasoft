function [fullName ok] = mrvSelectFile(rw, ext, windowTitle, startDir)
% Select a file name; the name can be to read or write
%
%  fullName = mrvSelectFile([rw], [ext], [windowTitle], [startDir])
%
%Purpose: 
%   The user is prompted to select a file in a directory.  The directory
%   name is a persistent variable, so the next time this routine is called,
%   the user starts in the last selected directory.
%
%   use rw = 'r' for reading and rw = 'w' for writing.
%   Default is read.  
%   You may also pass in an extension to use for filtering file names.
%	(This can be a simple name of an extension, such as 'mat', 'nii.gz',
%	etc, or a full cell array containing file patterns and descriptions, as
%	in UIGETDIR/UIPUTDIR.)
%   Returns fulName = [] on Cancel.
%
%
% Examples
%  fullName = mrvSelectFile('r');
%  fullName = mrvSelectFile('r','mat',[],'Save Mesh',fileparts(getVAnatomyPath));
%
% ras 10/07: removed pDir persistent variable, and removed
% dataType argument; this was added as a shell 3 years ago and abandoned.
% (And would need more information than is provided to work: you would need
% some sort of structure relating to your data, which shouldn't be involved
% in a function as low-level as this.)
%
% (c) Stanford VISTA Team

if notDefined('rw'), rw = 'r'; end
if notDefined('ext'), ext = '*'; end
if notDefined('windowTitle'), windowTitle = ''; end
if notDefined('startDir'), startDir = pwd;		end

if(startDir(end)~='*')
    startDir = fullfile(startDir, '*');
end

% ok = 0;

% ensure that ext is a cell array, 
if ~iscell(ext)
	ext = {ext};
end

% is "ext" a simple list of extensions/patterns, or does it also include
% descriptions of the file types (N x 2 array)?
if isvector(ext)
	% simple list of extensions: add a simple descriptor for each
	ext = ext(:); % first column is the extensions
	for n = 1:size(ext, 1)
		ext{n,2} = sprintf('%s files', ext{n,1});
	end
end
	
% ensure the pattern specifications have a '*' in them
for i = 1:size(ext, 1)
	if isempty( strfind(ext{i,1}, '*') )
		ext{i,1} = ['*.' ext{i,1}];
	end
end

switch lower(rw)
    case 'r'
        if(isempty(windowTitle)), windowTitle = 'MRV: Read Data'; end
        [fname, pname] = myUiGetFile(startDir, ext, windowTitle);
    case 'w'
        if(isempty(windowTitle)), windowTitle = 'MRV: Write Data'; end
        [fname, pname] = myUiPutFile(startDir, ext, windowTitle);
    otherwise
        error('Read/Write set incorrectly')
end

% If the user pressed cancel, clean up the mess and go home.
if isequal(fname,0) || isequal(pname,0), 
	fullName = []; 
	ok = 0;
elseif iscell(fname)
	% multiple files selected -- return a cell array of paths
	for ii = 1:length(fname)
		fullName{ii} = fullfile(pname, fname{ii});
	end
	pDir = pname; 		
	ok = 1;

else
	% single file selected
	fullName = fullfile(pname,fname); 
	pDir = pname; 
	ok = 1;
	
end


return;