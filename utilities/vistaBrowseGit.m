function vistaBrowseGit(vFileName)
% vistaBrowseGit([vFileName]);
%   
% Open a vistasoft function within your system's browser. If nargin=0, a
% browser will open to the main vistasoft repo on github.
% 
% INPUT: 
%   vFileName - STRING, name of a vistasoft function
% 
% EXAMPLE:
%   vistaBrowseGit('niftiWrite')
% 
% 
% (C) Stanford University, 2015
% 

baseURL='https://github.com/vistalab/vistasoft';

if notDefined('vFileName') || ~ischar(vFileName)
    s = '';
else
    baseURL = [baseURL '/blob/master'];
    s = which(vFileName);
    s = s(length(mrvDirup(mrvRootPath))+1:end);
end

web([baseURL s],'-browser')

return