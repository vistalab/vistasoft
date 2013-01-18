function newFlat
%
% function newFlat
%
% Prompt user for name of new flat directory. Make the directory
% and open a new flat window.
%
% djh, 2/2001

global HOMEDIR

flatSubDir = editableTextDialog('Enter new flat folder:','Flat');

% If "Cancel", then return
if isempty(flatSubDir)
    return
end
% flatSubDir must be 'Flat-*'
if findstr('Flat-',flatSubDir) ~= 1
    myErrorDlg('Flat folders must be named Flat-*')
end

pathStr = fullfile(HOMEDIR,flatSubDir);
% Error if this directory already exists
if exist(pathStr,'dir')
    myErrorDlg(['Folder: ',pathStr,' already exists.']);
end

mkdir(HOMEDIR,flatSubDir);
mkdir(pathStr,'ROIs');
installUnfold(flatSubDir,0);
openFlatWindow(flatSubDir);

return
