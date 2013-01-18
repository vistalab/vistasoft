function [magfiles, efiles, newestMagFile] = magFileList(pFileDir,fullpath);
% 
% Return a sorted list of mag and e-file names in the Pfile directory.
%
% [magList, eFileList, newestMagFile] = magFileList([pFileDir],[fullpath]);
%
% fullpath is an optional flag to return absolute paths (1) or 
% paths local to the pFileDir (0). [Default is 1, full paths]
%
% The optional 3rd output argument returns the most recently-created
% mag file.
%
% ras 03/05.
if notDefined('fullpath'), fullpath = 1; end
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
[magfiles efiles] = magSortByDate(magfiles,efiles,pFileDir);

if fullpath==1
    % convert to full paths
    for i = 1:length(magfiles)
        magfiles{i} = fullfile(pFileDir,magfiles{i});
        efiles{i} = fullfile(pFileDir,efiles{i});
    end
end

if nargout>=3
    % get most recent mag file (path)
    newestMagFile = fullfile(pFileDir,magfiles{end});
end

return
