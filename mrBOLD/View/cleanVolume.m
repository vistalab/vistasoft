function cleanVolume()
%
% function cleanVolume()
%
% Deletes:
%   Volume/coords.mat
%   Volume/dataType/corAnal.mat (for each dataType)
%   Volume/dataType/*.mat (all other parameter maps)
%
% If you change this function make parallel changes in:
%     cleanFlat, cleanDataType
%
% djh, 2/2001

global HOMEDIR
global dataTYPES

delete(fullfile(HOMEDIR,'Volume','coords.mat'));
for typeNum = 1:length(dataTYPES)
    dataTypeName = dataTYPES(typeNum).name;
    % Delete corAnal and parameter map files
    datadir = fullfile(HOMEDIR,'Volume',dataTypeName);
    delete(fullfile(datadir,'*.mat'));
    % Delete tSeries (if there are any)
    [nscans,scanDirList] = countDirs(fullfile(datadir,'TSeries','Scan*'));
    for s=1:nscans
        delete(fullfile(datadir,'TSeries',scanDirList{s},'*.mat'));
    end
end