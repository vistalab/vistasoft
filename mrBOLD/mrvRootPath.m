function rootPath=mrvRootPath()
%
%        rootPath =mrvRootPath;
%
% Determine path to root of the mrVista directory
%
% This function MUST reside in the directory at the base of the mrVista directory structure
%
% Wandell

rootPath=which('mrvRootPath');

[rootPath,fName,ext]=fileparts(rootPath);

return
