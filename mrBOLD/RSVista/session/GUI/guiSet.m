function  guiSet(property, val, varargin);
% Set Property values for the mrVista Session GUI.
%
% guiSet(property, value, <optional args>);
% 
% This consolidates a set of small snippets of accessor code to more
% easily read info from the GUI struct created by sessionGUI. Note
% that I did try to design the GUI structure to be pretty easily 
% accessible directly, but am sympathetic to the approach which strictly
% treats it like an object. For instance, to get the currently-selected
% scans, you could either use:
%   scans = guiGet('scans')
%       or
%   scans = GUI.settings.scan;
%
% PROPERTIES THAT CAN BE SET:
%   'scan' or 'scans': set scans. A value of 'all' will select all scans
%
% ras, 07/11/06.
mrGlobals2;

switch lower(property)
    case {'scans' 'scan' 'curscan' 'curscans' 'selectedscan' 'selectedscans'}
        if isequal(lower(val), 'all')
            val = 1:guiGet('numScans');
        end
        sessionGUI_selectScans(val);
        
end

return
