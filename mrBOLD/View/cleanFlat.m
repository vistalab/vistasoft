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
% jw, 7/2017: now creates backup rather than deleting

global HOMEDIR

curFlatDir = fullfile(HOMEDIR,flatSubdir);
backupFlatDir = fullfile(HOMEDIR,sprintf('deletedFlat_%s', ...
    datestr(now, 'yyyy-dd-mm-hh_MM-ss')));

movefile(curFlatDir, backupFlatDir);
 
return
