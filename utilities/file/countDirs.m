function [nDirs, dirList] = countDirs(dirName,path)

% [nDirs, dirList] = countDirs(dirName,[path])
%
% Finds directories that match dirName
%
%Inputs:  dirName    name of directory, can include wildcards
%                     i.e. '*' and '?'
%         path       directory to look in (default is current directory)
%
%Outputs: nDirs      number of matches
%         dirList    cell array of matching dir names
%
% 4/16/99  dbr   Rewritten from CountFiles with some efficiency improvements.

% RFD: matlab seems to handle the * wildcard ok, but it
% sometimes fails to deal with the ? wildcard appropriately.  
% So, we check for that and implement it ourselves if necessary.

if ~exist('path', 'var')
   path = '';
end
fullName = fullfile(path, dirName);
[pathName, name, ext] = fileparts(fullName);
dirName = [name, ext];

nDirs = 0;
dirList = {};

% Check for '?' wildcard:
qwc = findstr(dirName, '?');

if isempty(qwc)
  % No '?' case.
   allDirs = dir(fullName);
   dirInds = find([allDirs.isdir]);
   nDirs = length(dirInds);
   if nDirs == 0, return; end
   dirList = {allDirs(dirInds).name};
else
   % '?' in dirName case.
   allDirs = dir(pathName);
   dirInds = find([allDirs.isdir]);
   nTopDirs = length(dirInds);
   if nTopDirs == 0, return; end
   % check dirNames manually
   for ii=1:nTopDirs
     fn = allDirs(ii).name;
     if length(fn)==length(dirName)
       fn(findstr(dirName,'?')) = '?';
       if strcmp(fn, dirName)
	 nDirs = nDirs + 1;
	 dirList{nDirs} = allDirs(ii).name;
       end
     end
   end
end

if ~isempty(dirList)
   dirList = sort(dirList)';
end
