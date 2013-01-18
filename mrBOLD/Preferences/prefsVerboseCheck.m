function verbose = prefsVerboseCheck
% checks 'VISTA' preference groupfor a 'verbose' setting 
%
%   verbose = prefsVerboseCheck;
%
% This variable determines the level of feedback the user would like to
% receive on how mrVista is operating.
%
% PURPOSE: to allow the user to determine whether they want to get feedback
% on things like loading/saving of ROIs and maps; or waitbars when loading
% time series. For some uses, it may be nice to get this feedback (writing
% to a log; running interactively). Other times it may be a nuisance.
%
% For now, the 'verbose' flag is only intended to have two levels, 0
% (minimal feedback) and 1 (lots of feedback). If people's prefs differ
% more, we can add other levels (or more fancy things like a log file to
% keep track of mrVista analyses). Will return the current value of the
% preference, and if it's not set, will initialize it to 1, telling the
% user that it's doing so.
%
% ras, 09/2006.

if ~ispref('VISTA', 'verbose') 
    setpref('VISTA', 'verbose', 1);
    fprintf('[%s]: ', mfilename);
    fprintf('Initializing VISTA preference ''verbose'' to 1. This will provide \n');
    fprintf('feedback on things like loading/saving. To make it more silent, \n');
	fprintf('setpref(''VISTA'', ''verbose'', 0). \n');
end

verbose = getpref('VISTA', 'verbose');

return