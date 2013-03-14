function mrInit_sessionMigration()

%
% USAGE: Takes a session that has already been initialized with an older
% version of mrInit and update it to the newer version. All of the possible
% updates that can be applied will be applied based on the current
% situation of the session.
%
% INPUT: paramIn
% Parameter input that will be stripped of all capitalization as well as
% whitespace before it is attempted to be translated. If it is not
% translated, a warning is returned as well as an empty answer.
%
%
% OUTPUT: N/A
% This tool will report to the user via MATLAB command line, but will not
% output anything else.


loadSession; %Automatically checks if this directory exists and has mrSession

%Check to see if this session has already been updated for Inplane data,
%and, if not, run the update function
mrGlobals;


if ~isfield(mrSESSION.inplanes,'inplanePath')
    %Has not been updated yet, let's update
    ok = mrInit_updateInplaneSession;
else
    disp(sprintf('Inplane session update has already been applied. Will not re-apply.'));
    ok=1;
end %if


if ~ok
    %Error has occurred above, let's quit out of the update process
    ok = 0;
    warning('The update process has failed. Please check your session.');
    return
end %if

disp(sprintf('All updates have completed successfully.'));
return;