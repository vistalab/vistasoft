function rootPath=mrdRootPath()
%
%        rootPath =mrdRootPath;
%
% Determine path to root of the mrDiffusion directory
%
% This function MUST reside in the directory at the base of the mrDiffusion directory structure
%
% Wandell

rootPath=which('mrdRootPath');

[rootPath,fName,ext]=fileparts(rootPath);

return
