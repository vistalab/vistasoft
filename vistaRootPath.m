function rootPath = vistaRootPath()
% Determine path to root of the mrVista directory
%
%        rootPath = vistaRootPath;
%
% This function MUST reside in the directory at the base of the mrVista
% directory structure 
%
% Copyright Stanford team, mrVista, 2011

rootPath=which('vistaRootPath');

rootPath= fileparts(rootPath);

return
