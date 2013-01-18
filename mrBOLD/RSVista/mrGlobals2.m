% script mrGlobals2:
%
% defines global variables for mrVista 2.0
%
% (mrVista 3.0 will do away with globals, but this version
%  is designed to be back-compatible with the old session structures)
%
% ras, 07/10/06
% 

% Home directory (i.e., where mrSESSION.mat file sits).
% Set by mrLoadRet.m and mrInitRet.m
global HOMEDIR

% vAnatomy path
% Set by mrLoadRet.m
global vANATOMYPATH

% Structure that holds parameters about the scanning session and recon. 
% Loaded from mrSESSION.mat file.
global mrSESSION

% Structure that holds parameters about each scan, for each data type.
% Loaded from mrSESSION.mat file.
global dataTYPES

% Most info about the user interface will be stored in the new global
% variable GUI:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This will have info on the interface created by the function
% sessionGUI:
global  GUI

% ...however, these three "view" variables are holdovers which will contain
% some info about the interface parameters and segmentation, which will be
% kept in mrVista 2 to allow legacy code to work:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPLANE data: data in the coordinate space in which it was collected
% during a particular session
global INPLANE

% VOLUME data: data co-registered to a reference frame, such as a subject's
% reference anatomy (or, down the line, group analyses)
global VOLUME

% FLAT data: data from a segmented gray volume, projected onto a flat 2-D
% surface. (Mostly legacy code):
global FLAT

% When more than one flat view is open, selectedFLAT specifies which one
% to use (e.g., when mapping ROIs or data from flat to volume). Likewise
% for inplane and volume windows. These globals are reset when windows
% are first opened, and by refreshView.
% (these should go away soon, and be consolidated into the GUI variable)
global selectedINPLANE 
global selectedVOLUME
global selectedFLAT

return;

