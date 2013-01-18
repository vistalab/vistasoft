function cleanFlat(flatSubdir)
%
% function cleanFlat(flatSubdir)
%
% Deletes:
%   flatSubdir/coords.mat
%   flatSubdir/dataType/corAnal.mat (for each dataType)
%   flatSubdir/dataType/*.mat (all other parameter maps)
%
% If you change this function make parallel changes in:
%     cleanGray, cleanDataType
%
% djh, 2/2001

global HOMEDIR
global dataTYPES

delete(fullfile(HOMEDIR,flatSubdir,'coords.mat'));
delete(fullfile(HOMEDIR,flatSubdir,'anat.mat'));
delete(fullfile(HOMEDIR,flatSubdir,'coordsLevels.mat')); % flat level view
for typeNum = 1:length(dataTYPES)
    dataTypeName = dataTYPES(typeNum).name;
    % Delete corAnal and parameter map files
    datadir = fullfile(HOMEDIR,flatSubdir,dataTypeName);
    delete(fullfile(datadir,'*.mat'));
    % Delete tSeries (if there are any)
    [nscans,scanDirList] = countDirs(fullfile(datadir,'TSeries','Scan*'));
    for s=1:nscans
        delete(fullfile(datadir,'TSeries',scanDirList{s},'*.mat'));
    end
end

% The flat ROIs query seems unnecessary -- esp. now that KGS
% lab saves all ROIs in a central FlatROIs dir by the vAnat.
% ras, 10/04
% resp = questdlg(['Delete ',flatSubdir,'/ROIs/*.mat?']);
% if strcmp(resp,'Yes')
%     delete(fullfile(HOMEDIR,flatSubdir,'ROIs','*.mat'));
% end
 
return
