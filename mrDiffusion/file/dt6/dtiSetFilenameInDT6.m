function dtiSetFilenameInDT6(dt6File,strname,val)
%
%  dtiSetFilenameInDT6(dt6File,strname,val)
%
%Author: AJS
%Purpose:
%   Set a filename in the dt6 file.  This is here because we may expect
%   standard file naming conventions.  Currently, we expect that the files
%   are relative to the subject directory.
%
% HISTORY:
%  2007.07.20 AJS: wrote it.


% Filenames are stored relative to the subject directory
subjDir = dtiGetSubjDirInDT6(dt6File);

% Load the dt6 file
tempdt6 = load(dt6File);


% Get relative pathname
[p,f,ext] = fileparts(val);
relVec{1} = [f ext];
while ~strcmp(subjDir,p)
    [p,f] = fileparts(p);
    relVec{end+1} = f;
end

% Set the filename with the relative path
tempdt6.files = setfield(tempdt6.files,strname,fullfile(relVec{end:-1:1}));

% Save the dt6 to file
save(dt6File,'-struct','tempdt6');

return;