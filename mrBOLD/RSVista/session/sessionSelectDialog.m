function session = sessionSelectDialog(N, prompt, startDir);
% Select a mrVista session/s using a graphical dialog, returning the full
% path to that session.
%
%  sessionPath = sessionSelectDialog(<N=1>, <prompt>, <startDir=pwd>);
%
%  N specifies the number of sessions to select, defaulting to 1. 
%  If N = 1, a single input dialog is used to get one directory, returning
%            it as a string. 
% 
%  If N > 1, a multiple-selection dialog is used to get many directories,
%            returning them as a cell array of strings.
% 
% prompt is an optional title for the dialog. Defaults to 'Select a mrVista
% session...'.
%
% startDir is the startind directory for the dialog. Defaults to working directory.
%
% ras, 07/06.
if notDefined('N'), N = 1; end
if notDefined('startDir'), startDir = pwd; end
if notDefined('prompt'), prompt = 'Select a mrVista session...'; end

if N==1
    session = uigetdir(startDir, prompt);
else
    session = selectSessions(startDir, N);
end

return
