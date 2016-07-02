function rootPath=mrvTestRootPath()
%Determine path to root of the mrVista unit testing directory.  
%
%        rootPath = mrvTestRootPath;
%
% This file and similarly named ones are used to identify the root
% directory of important repositories or files.
%
% This one is used as part of the testing of vistasoft
%
% This function MUST reside in the directory at the base of the vistatest
% directory structure.
%
% mrVista Team

rootPath = which('mrvTestRootPath');

rootPath = fileparts(rootPath);

return
