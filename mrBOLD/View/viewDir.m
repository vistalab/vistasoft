function str = viewDir(view);
%
% str = viewDir(view);
%
% Returns the HOMEDIR/view.subdir directory.
% E.g., 'mySession/Gray' for gray views.
%
% Intended replacement for homeDir, as that
% kept getting confused w/ the HOMEDIR global 
% variable.
%
% While I'm at it, tries to make it if it 
% doesn't exist.
%
%  ras 03/05.
global HOMEDIR

str = fullfile(HOMEDIR,view.subdir);

if ~exist(str,'dir')
    fprintf('Trying to make %s...',str);
    try
        [success, message] = mkdir(HOMEDIR,view.subdir);
    catch
        fprintf('Whoops, didn''t succed. Maybe a permissions problem?');
        fprintf('\n Message: %s',message);
    end
    fprintf('\n');
end

return
