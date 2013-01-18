function rootPath=mrv2RootPath()
%
%        rootPath =mrv2RootPath;
%
% Determine path to root of the mrVista directory
%
% This function MUST reside in the directory at the base of the mrVista directory structure
%
% Wandell
% ras, imported into mrVista 2.0, 07/05
rootPath = fileparts(which(mfilename));
return
