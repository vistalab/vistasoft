function [nFiles,fileList] = countFiles(filename,dr)
%[nFiles,fileList] = countFiles(filename,[dr])
%
%Inputs:  filename    name of file, can include wildcards
%                     i.e. '*' and '?'
%         dr          directory
%
%Outputs: nFiles      number of matches
%         fileList    cell array of matching file names

%4/10/98  gmb   Wrote it.
%9/18/98  rmk   Added extra disjunction to string comparison for compatibility
%               with linux machines
%99.02.12 rfd	 Replaced unix(unixStr) with code that will work on all
%					 platforms, including NT.

% RFD: matlab seems to handle the * wildcard ok, but it
% sometimes fails to deal with the ? wildcard appropriately.  
% So, we check for that and implement it ourselves if necessary.

if ~exist('dr','var')
   dr = '';
end
if ~exist('filename','var')
    filename = '*';
end

nFiles = 0;
fileList = {};
qwc = findstr(filename,'?');
if isempty(qwc)
   allFiles = dir(fullfile(dr,filename));
   for ii=1:length(allFiles)
      if ~allFiles(ii).isdir
      	nFiles = nFiles + 1;
      	fileList{nFiles} = allFiles(ii).name;
      end
   end
else
   % get all the files in the directory
   allFiles = dir(dr);
   for ii=1:length(allFiles)
      if ~allFiles(ii).isdir
         % check filenames ourselves
         fn = allFiles(ii).name;
         if length(fn)==length(filename)
            fn(findstr(filename,'?')) = '?';
            if strcmp(fn, filename)
               nFiles = nFiles + 1;
               fileList{nFiles} = allFiles(ii).name;
            end
         end
      end
   end
end

if ~isempty(fileList)
   fileList = sort(fileList)';
end
