function full = fullpath(pth)
%
% full = fullpath(pth);
%
% Given a string specifying a path which may be an absolute path,
% or a path relative to the current directory, always return 
% an absolute, full path string. Platform-independent.
%
% Ex: if the current directory is '/usr/me' and the pth string is 
% 'Inplane/Original', will return '/usr/me/Inplane/Original'. But if the
% pth string is '/usr/someone_else', will return '/usr/someone_else'.
%
% ras, 11/2005.
% ras, 10/30/2006: deals w/ empty paths now.
if isempty(pth), full = pwd; return; end

if isunix
    % Check for the root file separator '/' for absolute paths
    if isequal(pth(1), filesep)
        full = pth;
    else
        full = fullfile(pwd, pth);
    end
elseif ispc
    % check if the drive colon is specified as 2nd char: e.g., 'C:\'
    if isequal(pth(2), ':')
        full = pth;
    else
        full = fullfile(pwd, pth);
    end
else
    % not unix-y (incl. mac) or pc -- ?
    msg = 'This computer not identified as PC, Mac OS X or Unix. ';
    msg = [msg 'Sorry, fullpath can''t work for this platform. '];
    msg = [msg 'Returning un-modified input path.'];
    warning(msg);
    full = pth;
end

return
