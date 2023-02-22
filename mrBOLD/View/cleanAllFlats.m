function cleanAllFlats()
%
% function cleanAllFlats()
%
% Deletes:
%   flatSubdir/coords.mat
%   flatSubdir/dataType/corAnal.mat (for each dataType)
%   flatSubdir/dataType/*.mat (all other parameter maps)
% for all flatSubdirs
%
% djh, 2/2001
global HOMEDIR

[nDirs,dirList] = countDirs(fullfile(HOMEDIR,'Flat*'));
for d = 1:nDirs
    cleanFlat(dirList{d});
end