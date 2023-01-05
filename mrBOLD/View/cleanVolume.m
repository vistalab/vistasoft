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

curVolumeDir = fullfile(HOMEDIR,'Volume');
backupVolumeDir = fullfile(HOMEDIR,sprintf('deletedVolume_%s', ...
    datestr(now, 'yyyy-dd-mm-hh_MM-ss')));

if exist(curVolumeDir, 'dir')
    movefile(curVolumeDir, backupVolumeDir);
end
