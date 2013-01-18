function defaultName = dtiNameDefault(currentName)
%
%Author: BW
%Purpose:
%   Translate name characterstics for efficiency and Linux.  As we get
%   smarter, we might do better with this translation routine.
% 

defaultName = [strrep(currentName, ' ', '_') '.mat'];

% Some older files have these long strings.  I am changing them over.  Is
% that OK?
defaultName = strrep(defaultName,'_(NOT)_','-');
defaultName = strrep(defaultName,' (NOT) ','-');
defaultName = strrep(defaultName,'_(AND)_','+');
defaultName = strrep(defaultName,' (AND) ','+');

return;