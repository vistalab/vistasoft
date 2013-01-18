function fullName = mrvSelectDataFile(dataType,rw,fileFilter,windowTitle)
%Select a data file name for reading or writing
%
%    fullName = mrvSelectDataFile(dataType,[rw],[fileFilter],[windowTitle])
%
% Use this routine to choose a data file for reading or writing.  
%
% The parameter dataType is a clue about the proper directory to use to
% find or write the file.  At present, only 'stayput' is defined. 
% dataType can also be a path to a starting directory.
%
% To specify whether the file is for reading or writing, use rw = 'r' for
% reading and rw = 'w' for writing. Default is read.
%
% You may pass in an extension list fileFilter, a cellarray, to filter
% file names. 
%
% WINDOWTITLE is a string for the read window to help the user know the
% purpose. 
%
% Returns fulName = [] and prints 'User canceled' on Cancel.
%
% The current dataType options are:
%
%  {'session','stayput'} or undefined - last selected directory, or the
%    current working directory if none was selected previously.
%
%    
% Examples
%     fullFile = mrvSelectDataFile('stayput','r',{'*.m; *.mat; *.jpg'},'Hello')
%     fullFile = mrvSelectDataFile('stayput','r','*.dat','Choose vAnatomy')
%

% TODO
% Possibly, we should enforce the extension on the returned file name?

if notDefined('dataType'), dataType = 'stayput'; end
if notDefined('rw'),  rw = 'r'; end
if notDefined('fileFilter'), fileFilter = '*.*'; end

curDir = pwd;

% We remember the last directory the user chose. On the first call, this
% variable is empty.  But from then on, we use it.
persistent pDir;

% I think we need to add to this in the future.  Don't know all the cases.
% The two types of anatomies, ROIs, other stuff?
switch lower(dataType)
    case {'session','stayput'}
        if isempty(pDir), fullPath = pwd;
        else fullPath = pDir;
        end
    case {'windowsanatomy'}
        % Something like this?
        if exist('X:\anatomy', 'dir'), fullPath = 'X:\anatomy'; end
    case {'linuxanatomy'}
        % Figure out
        % if exist('X:\anatomy', 'dir'), fullPath = 'X:\anatomy'; end
    otherwise
        % figure it's a directory
        pDir = dataType;
end


chdir(fullPath);
switch lower(rw)
    case 'r'
        if notDefined('windowTitle'), windowTitle = 'mrVista: Read Data'; 
        end
        [fname, pname] = uigetfile(fileFilter, windowTitle);
    case 'w'
        if notDefined('windowTitle'), windowTitle = 'mrVista: Write Data'; 
        end
        [fname, pname] = uiputfile(fileFilter, windowTitle);
    otherwise
        error('Read/Write set incorrectly')
end

% Clean up and go home
if isequal(fname,0) | isequal(pname,0)
    fullName = [];
    disp('User canceled.')
else
    fullName = fullfile(pname,fname);
    pDir = pname;
end

chdir(curDir)

return;
