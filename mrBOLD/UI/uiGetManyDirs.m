function dirList = uiGetManyDirs(checkedFile);
% function dirList = uiGetManyDirs([checkedFile]);
% 
% Ask the user to select many Directories.
% Check if checkedFile (optional) is existent in each selected dir. If not,
% ask the user if the dir will be selected anyway.
% Example: uiGetManyDirs('mrSESSION.mat');
%
% 2004.02.14 Junjie Liu 

if ~exist('checkedFile','var'); checkedFile = ''; end; % empty will be ok for all dir anyway.

suggestDir = pwd;
dirList = cell(0);
selecting = 1;
startover = 1;
while startover
    while selecting
        getDir = uigetdir(suggestDir,['Select Directory # ',int2str(length(dirList)+1)]);
        if getDir == 0; % clicked cancel
            selecting = strcmp(questdlg('You clicked Cancel. Shall I continue selecting?',...
                'Select Multiple Directories','Yes','No','Yes'),'Yes');
        else % dir selected. check if checkedFile exists
            if isempty(dir(fullfile(getDir,checkedFile)));
                if strcmp(questdlg(['File ',checkedFile,' not exist in last selected dir. Still select it anyway?'],...
                        'File Not Found','Yes','No','No'),'Yes');
                    dirList = [dirList,{getDir}]; % as a cell array
                end
            else
                dirList = [dirList,{getDir}];
            end
            selecting = strcmp(questdlg('Continue selecting?','Select Multiple Directories',...
                'Yes','No','Yes'),'Yes');
            suggestDir = getDir;
        end
    end
    confirm = questdlg(char([{'Your selected Dirs are the following'},dirList,{'Are they correct?'}]),...
        'Confirm','Yes','No,StartOver','No,Cancel','Yes');
    startover = strcmp(confirm,'No,StartOver'); % startover - select again
    if strcmp(confirm,'No,Cancel'); dirList = cell(0); end; % cancel - toss selection and quit
end

return
