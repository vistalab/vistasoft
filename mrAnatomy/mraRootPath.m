function rootPath=mraRootPath()
% Determine path to root of the mrAnatomy directory
%
%        rootPath = mraRootPath;
%
% This function MUST reside in the directory at the base of the mrAnatomy
% directory structure 
%
% VISTASOFT, Stanford, Wandell

rootPath=which('mraRootPath');

[rootPath,fName,ext]=fileparts(rootPath);

return
