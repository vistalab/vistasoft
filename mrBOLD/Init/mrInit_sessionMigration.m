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

try
    if ~isfield(mrSESSION.inplanes,'inplanePath')
        %Has not been updated yet, let's update
        mrInit_updateInplaneSession;
    else
        disp(sprintf('Inplane session update has already been applied. Will not re-apply.'));
    end %if
    
catch err
    error('The Inplane session update has not completed successfully. All changes rolled back. Please check your session.');
    rethrow(err);
end %try

disp('Inplane session update has been applied correctly.');

try
    if ~isfield(mrSESSION.functionals(1),'keepFrames')
        %Has not been updated yet, let's update
        mrInit_updateSessiontSeries;
    else
        disp(sprintf('tSeries session update has already been applied. Will not re-apply.'));
    end %if
catch err
    error('The tSeries session update has not completed successfully. Changes just to it have been rolled back. Please check your session.');
    rethrow(err);
end %try

disp('tSeries session updated has been applied correctly.');

disp('All updates have completed successfully.');
return;