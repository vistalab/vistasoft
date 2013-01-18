% mrGlobals (Script)
% Defines global variables for mrLoadRet
%
% djh, 1/10/97
% 

global mrLoadRetVERSION
mrLoadRetVERSION = 3.0;

% Home directory (i.e., where mrSESSION.mat file sits).
% Set by mrLoadRet.m and mrInitRet.m
global HOMEDIR
if isempty(HOMEDIR), HOMEDIR = pwd; end

% vAnatomy path
% Set by mrLoadRet.m
global vANATOMYPATH

% Structure that holds parameters about the scanning session and recon. 
% Loaded from mrSESSION.mat file.
global mrSESSION

% Structure that holds parameters about each scan, for each data type.
% Loaded from mrSESSION.mat file.
global dataTYPES

% Window handle for the current graph window
global GRAPHWIN

% Structure that holds the INPLANE view
global INPLANE
% Structure that holds the VOLUME view
global VOLUME
% Structure that holds the FLAT view
global FLAT

% When more than one flat view is open, selectedFLAT specifies which one
% to use (e.g., when mapping ROIs or data from flat to volume). Likewise
% for inplane and volume windows. These globals are reset when windows
% are first opened, and by refreshView.
global selectedINPLANE 
global selectedVOLUME
global selectedFLAT

return;

