function ok = mrInit_updateInplaneSession()

%
% USAGE: Takes a session that has already been initialized with an older
% version of mrInit and update it to the newer version. The newer version
% is of 2013-03-01 and it no longer saves the Inplane data out to a matlab
% matrix file.
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

%We should have access to a mrSESSION as well as an anat.mat 