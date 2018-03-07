function foundit = check4File(filename, format)
%
% foundit = check4File(filename, [format='.mat'])
%
% AUTHOR:  Boynton
% PURPOSE:
%  Check for a file with the specified extension in the current working
%  directory, or relative to the current directory.
%  This is a special case of exist.
%
% Modified 08.20.98 WP/BW
%
%  We used the Matlab exist function here, so we don't need a
%  unix call.  In other ways, we left it compatible with the
%  old check4file.  We wrote it in a way to try  to prevent Matlab
%  for checking for other instances of the file in other
%  directories along the path, the default Matlab behavior.
%
%    BUGS:  This routine is only checking for files with a .mat
%    extension. It should be called something else, like
%       check4MatFile.  Probably, it shouldn't exist at all, and
%    we should only use exist and force the code to be explicit
%    about the file name and path.
%
%   09/06 SOD: Actually check2File is also used for non-'.mat' (such as
%               .gray) files so, removed '.mat' back to '.'
%   09/06 RAS: OK, but then why only enforce .mat files? This defeats the stated
%               purpose of the code, which is to check for .mat files. 
%               Looks from the comments like this is a lasting issue.
%               So, in an attempt to resolve this, I added the second
%               'format' flag which defaults to '.mat'. If you want to use
%               this for gray files, you'll need to pass the alternate
%               extension in at the places that use it.


if notDefined('format'), [~,~,format] = fileparts(filename); end
if isempty(format), format = '.mat'; end    

% Add the .mat extension if it isn't passed in
if isempty(strfind(filename, format))
    filename = [filename format];
end

%  If the filename passed in has a / or a \ in it, leave things alone.
%  Otherwise, preappend './'.  This is to stop Matlab
%  from finding files with the same name elsewhere on the path.
%
if isempty(strfind(filename,'/')) && isempty(strfind(filename,'\'))
    filename = ['./' filename];
end

%  Specify the full path so that we will only find one in the
%  current directory, nowhere else in the path
%
if exist(filename,'file')
    foundit = 1;
else
    foundit = 0;
end

return;



