function extended = prefsExtendedGrayCheck;
%
% extended = prefsExtendedGrayCheck;
%
% Checks the 'extendedGrayFields' VISTA preference, initializing
% it if it doesn't exist. This field determines whether gray views
% will load 
%
% ras, 03/2007.
if ~ispref('VISTA', 'extendedGrayFields') 
    setpref('VISTA', 'extendedGrayFields', 1);
    fprintf('\n\n[%s]: ', mfilename);
    fprintf('Initializing VISTA preference ''extendedGrayFields'' to 1. \n');
    fprintf('This will cause gray/volume views to load extended fields, \n');
	fprintf('such as inplane indices corresponding to the data and \n');
	fprintf('separate left/right nodes (in addition to combined nodes).\n');
	fprintf('To _not_ load these fields until needed, run: \n\n]\n');
	fprintf('setpref(''VISTA'', ''extendedGrayFields'', 0). \n');
end

extended = getpref('VISTA', 'extendedGrayFields');

return