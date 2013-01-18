function subdir = getFlatSubdir
%
% function subdir = getFlatSubdir
%
% djh, 2/14/2001

global HOMEDIR

% Get list of subdirectories
flatDirs = dir(fullfile(HOMEDIR,'Flat*'));
for ii=1:length(flatDirs)
   flatDirList{ii} = flatDirs(ii).name;
end

% Pick one
switch length(flatDirs) 
case 0
    myErrorDlg(['No Flat directories. Use Install New Unfold ' ...
                'from the Segmentation menu to make one.']);
    
case 1
    subdir = flatDirList{1};
    
otherwise
    dlg.fieldName = 'whichFlat';
    dlg.style = 'listbox';
    dlg.list = flatDirList;
    dlg.value = 1;
    dlg.string = 'Select A Flat Directory:';
    
    resp = generalDialog(dlg);
    
    subdir = resp.whichFlat{1};  
end

return
