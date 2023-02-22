function FatalInitError(str)
%
% function FatalInitError(str)
%
% str: error string
%
% queries user, then blasts the entire thing, deleting mrSESSION and any% tSeries files
% have been extracted.
%
% djh, 9/26/2001
global HOMEDIR
deleteFlag = questdlg([str,' Start from scratch?'],...
    'Fatal mrInitRet error','Yes','No','Yes');

if strcmp(deleteFlag,'Yes')
    % Delete everything
    sessionFile = fullfile(HOMEDIR,'mrSESSION.mat');
    if exist(sessionFile,'file');
        delete(sessionFile);
    end
    datadir = fullfile(HOMEDIR,'Inplane');
    % Delete anat, if it exists
    delete(fullfile(datadir,'*.mat'));
    % Delete tSeries (if there are any)
    [nscans,scanDirList] = countDirs(fullfile(datadir,'Original','TSeries','Scan*'));
    for s=1:nscans
        delete(fullfile(datadir,'TSeries',scanDirList{s},'*.mat'));
    end
end
clear all
close all