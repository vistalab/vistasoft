function stat = MakeDir(dirName, rootName)
%
% function stat = MakeDir(rootName, dirName);
%
% Creates directory 'dirName' in the indicated root directory if
% it doesn't exist already. 
% 
% dbr, 3/99

if exist('rootName', 'var')
  fullName = fullfile(rootName, dirName);
else
  fullName = dirName;
end

if ~exist(fullName, 'dir')
  ok = mkdir(rootName,dirName);
  if ok, disp(['Created directory: ', dirName]); end
end

stat = exist(fullName, 'dir');
