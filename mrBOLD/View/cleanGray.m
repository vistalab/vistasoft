function cleanGray()
%
% function cleanGray()
%
% Deletes:
%   Gray/coords.mat
%   Gray/dataType/corAnal.mat (for each dataType)
%   Gray/dataType/*.mat (all other parameter maps)
%
% If you change this function make parallel changes in:
%     cleanFlat, cleanDataType
%
% djh, 2/2001
% jw, 7/2017: now creates backup rather than deleting

global HOMEDIR

curGrayDir = fullfile(HOMEDIR,'Gray');
backupGrayDir = fullfile(HOMEDIR,sprintf('deletedGray_%s', ...
    datestr(now, 'yyyy-dd-mm-hh_MM-ss')));

if exist(curGrayDir, 'dir')
    movefile(curGrayDir, backupGrayDir);
end
