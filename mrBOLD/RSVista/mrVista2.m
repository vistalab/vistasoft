% script mrVista2:
% ****** MAIN START SCRIPT FOR MRVISTA 2 *****
% 
% This script is intended to be a small file that does the following:
%  (1) checks the current directory if a mrVista-initialized session is
%  present;
%  (2) if so, starts the mrVista session GUI;
%  (3) if not, prompts to initialize a new functional session or volume
%  anatomy.
% 
% Also sets the global variables for the program.
%
% ras, 07/10/2006.
mrVersion = '2.0.1'; % reaallly beta version...

% set global variables
mrGlobals2;

% report on the current version,
% initializing a global variable along the way
if ~ispref('VISTA', 'verbose')
    verbose = 1; % default to normal verbosity
    setpref('VISTA', 'verbose', verbose)    
else
    verbose = getpref('VISTA', 'verbose');
end

if verbose==1
    fprintf('mrVista %s running on MATLAB %s\n', mrVersion, version);
end
    
% right now, just start up the session GUI (we'll do the rest later)
if ~isempty(GUI) && ishandle(GUI.fig)
    figure(GUI.fig);
else
    sessionGUI;
end

return
