function ndef = notDefined( varString )
% Test whether a variable (usually a function argument) is defined
%
%    ndef = notDefined( varString )
%
% This routine is used to determine if a variable is defined in the calling
% function's workspace.  A variable is defined if (a) it exists and (b) it
% is not empty. This routine is used throughout the ISET code to test
% whether arguments have been passed to the routine or a default should be
% assigned.
%
% notDefined: 1 (true) if the variable is not defined in the calling workspace 
%             0 (false) if the variable is defined in the calling workspace
%
%  Defined means the variable exists and is not empty in the function that
%  called this function.  
%
%  This routine replaced many calls of the form
%    if ~exist('varname','var') | isempty(xxx), ... end
%
%    with 
%
%    if ieNotDefined('varname'), ... end
%
% bw summer 05 -- imported into mrVista 2.0
% ras 10/05    -- changed variable names to avoid a recursion error.
% ras 01/06    -- imported back into mrVista 1.0; why should we keep
% typing 'ieNotDefined' in front of every function?

if (~ischar(varString)), error('Varible name must be a string'); end

% ndef = 0;  % Assume the variable is defined

str = sprintf('''%s''',varString);   
cmd1 = ['~exist(' str ',''var'') == 1'];
cmd2 = ['isempty(',varString ') == 1'];
% cmd = [cmd1, ' | ',cmd2];

% If either of these conditions holds, then not defined is true.
ndef = evalin('caller',cmd1);     % Check that the variable exists in the caller space
if ndef,  return;                 % If it does not, return with a status of 0
else 
    ndef = evalin('caller',cmd2); % Check if the variable is empty in the caller space
    if ndef , return;
    end
end

return;
