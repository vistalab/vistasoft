function file = mrvFindFile(fileName,directory,mode)
% 
%  file = mrvFindFile(fileName,directory,mode)
% 
% This simple function is designed to find a return a full path to a given
% file within a directory. It will search the directory tree recursively to
% find the file and give you it's full path. If more than one file is found
% the will be returned in a string array.
%
% 
% MODES:
% 
%   [1, 'all' 'allfollow'] 
%       By default the mode = [1], which allows the code to follow soft
%       links.
% 
%   [2, 'allnofollow'] 
%       Link following can be turned off by setting mode = [2]. 
% 
%   [3, 'first', 'firstfollow'] 
%       Follow soflinks but only return the first matching result.
% 
%   [4, 'firstnofollow'] 
%       Do not follow soft links and only return the first matching
%       result.
% 
%   [5, 'firstnot','notfirst']
%       Return the first file that is *not* matching 'fileName'.
% 
%   [6, 'not', 'allnot','notall']
%       Return *all* files that do *not* match 'fileName'.
% 
% EXAMPLE:
%   
%   file = mrvFindFile('dt6.mat',pwd,'first')
% 
%   file =
% 
%       /biac4/wandell/data/westonhavens/results/testlab/20130509_1152_4534/dt6/dt6.mat
% 
% 
% (C) Stanford University - VISTA LAB, 2014 - lmperry@stanford.edu
% 


%%
if notDefined('directory') 
    directory = pwd;
end

if notDefined('mode')
	mode = 1;
end	

[ p, ~ ] = fileparts(directory);

if isempty(p)
    directory = fullfile(pwd,directory);
end

file = '';
tn   = tempname;

switch mode
    case {1, 'all', 'allfollow'}
        cmd = ['find ' directory ' -follow -type f -name "' fileName '" | tee > ' tn];
    
    case {2, 'allnofollow'}
        fprintf('\n[%s] - Not following softlinks.\n',mfilename);
        cmd = ['find ' directory ' -type f -name "' fileName '" | tee > ' tn];
    
    case {3, 'first', 'firstfollow'}
        cmd = ['find ' directory ' -follow -type f -name "' fileName '" -print | head -n 1 | tee > ' tn];
    
    case {4, 'firstnofollow'}
        cmd = ['find ' directory ' -type f -name "' fileName '" -print | head -n 1 | tee > ' tn];
    
    case {5, 'firstnot', 'notfirst'}
        cmd = ['find ' directory ' -follow -type f ! -name "' fileName '" -print | head -n 1 | tee > ' tn];
    
    case {6, 'not', 'allnot'}
        cmd = ['find ' directory ' -follow -type f ! -name "' fileName '" | tee > ' tn];
       
    otherwise
        cmd = '';
        fprintf('\n[%s] - Invalid mode.\n',mfilename)
        help(mfilename);
end
 
% Run the command 
[status, ~] = system(cmd);
if status ~= 0 
    warning('There was a problem finding files.');
    return
end

file = readFileList(tn);
delete(tn);

% Return an empty string if there were no results. 
if isempty(file)
    file = '';
end

% If there's only one file give it back as a string
% NOT sure this is the right thing to do...
% if numel(file) == 1
%     file = file{1};
% end


%%
return


