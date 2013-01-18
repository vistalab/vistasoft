function fname = dtiGetFilenameInDT6(dt6File,strname)
%
%  fname = dtiGetFilenameInDT6(dt6File,strname)
%
%Author: AJS
%Purpose:
%   Get a filename in the dt6 file.  This is here because we may expect
%   standard file naming conventions.  Currently, we expect that the files
%   are relative to the subject directory.
%
% HISTORY:
%  2007.07.20 AJS: wrote it.

% Filenames are stored relative to the subject directory
subjDir = dtiGetSubjDirInDT6(dt6File);

% Filenames are stored relative to the homeDir that is stored
tempdt6 = load(dt6File);

if strcmp(strname,'homeDir')
    fname = tempdt6.files.homeDir;
elseif(isfield(tempdt6,'files')&&isfield(tempdt6.files,strname))
    fname = fullfile(subjDir,getfield(tempdt6.files,strname));
else
    fname = [];
end

return;