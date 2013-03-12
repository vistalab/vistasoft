function ok = mrInit_sessionMigration()

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
% OUTPUT: ok
% error code for whether the migration completed successfully

% This migration tool takes an anat.mat file that presently exists and
% makes some assumptions about its orientation. Specifically, it is assumed
% that it is already in ARS format (which is the normal display format).
% Once this has been found, the migration tool creates a nifti structure
% for this data matrix.

loadSession; %Automatically checks if this directory exists and has mrSession

%Check to see if this session has already been updated for Inplane data,
%and, if not, run the update function

if isempty(sessionGet(mrSESSION,'Inplane Path'))
    %Has not been updated yet, let's update
    ok = mrInit_updateInplaneSession;
end %if


if ~ok
    %Error has occurred above, let's quit out of the update process
    ok = 0;
    warning('The update process has failed. Please check your session.');
    return
end %if