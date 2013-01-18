function [magFile, magfiles, efiles] = newestMagFile(pFileDir);
% 
% [magFile, magList, eFileList] = newestMagFile([pFileDir]);
%
% Return a path to the most recently-created
% P*.7.mag file that has a corresponding E-file
% header in the specified dir. pFileDir defaults
% to pwd.
%
% Also returns a sorted list of mag and e-file 
% names in the Pfile directory.
%
% ras 03/05.
if ieNotDefined('pFileDir')
    % for rtviz
    pFileDir = '/lcmr3/mrraw';
    if ~exist(pFileDir,'dir')
        pFileDir = pwd;
    end
end

% check that dir exists
if ~exist(pFileDir,'dir')
    error(sprintf('%s is not a working directory.',pFileDir))
end

% get list of E-files first
efiles = dir(fullfile(pFileDir,'E*P*.7'));
efiles = {efiles.name};

% get efile numbers
enums = [];
for i = 1:length(efiles)
    enums(i) = str2num(efiles{i}(end-6:end-2));
end

% get list of mag files
magfiles = dir(fullfile(pFileDir,'P*.7.mag'));
magfiles = {magfiles.name};

% get mag nums
magnums = [];
for i = 1:length(magfiles)
    magnums(i) = str2num(magfiles{i}(2:6));
end

% find seq nums with both mag files and e files
[goodNums Imag Ie] = intersect(magnums,enums);
efiles = efiles(Ie);
magfiles = magfiles(Imag);

% check for empty set
if isempty(magnums) & isempty(enums)
    msg = sprintf('There are no mag/E-file pairs in this directory: %s',pFileDir);
    warning(msg);
    magFile = '';
    return
end

% sort by date
callingDir = pwd;
[magfiles efiles] = SortMagFiles(magfiles,efiles,magnums,enums,pFileDir);

% get most recent mag file (path)
magFile = fullfile(pFileDir,magfiles{end});
    
return
