function mrvBrowseSVN(fileName)
%  
% mrvBrowseSVN(fileName)
% 
% Deprecated function - wraps vistaBrowseGit.m
% 
% See also: 
%   vistaBrowseGit.m
% 
% (C) Stanford University, 2015
% 

if nargin == 0
    help(mfilename)
    return
end

disp('This function is deprecated. Using vistaBrowseGit instead.');
vistaBrowseGit(fileName)

return