function file = mrvFindFile(fileName,directory,mode)
% 
%  file = mrvFindFile(fileName,directory,mode)
% 
% This simple function is designed to find a return a full path to a given
% file within a directory. It will search the directory tree recursively to
% find the file and give you it's full path. 
%
% VALID MODES:
%   [1] or [2]:
%   By default the mode = 1, which allows the code to follow soft links.
%   This can be turned off by setting mode = 2.
% 
% EXAMPLE:
%   
% file = mrvFindFile('dt6.mat',pwd,1)
% 
%   file =
% 
%       /biac4/wandell/data/westonhavens/results/testlab/20130509_1152_4534/dt6/dt6.mat
% 
% (C) Stanford University - VISTA LAB, 2014
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

switch mode 
	case 1
		cmd = ['find ' directory ' -follow -type f -name "' fileName '"'];
	case 2
        fprintf('\n[%s] - Not following softlinks.\n',mfilename);
		cmd = ['find ' directory ' -type f -name "' fileName '"'];
	otherwise
		cmd = '';
        fprintf('\n[%s] - Invalid mode.\n',mfilename)
        help(mfilename);
end
 
% Run the command 
[status, result] = system(cmd);
if status ~= 0 
    warning('There was a problem finding files.');
    return
end


file =  regexprep(result,'\r\n|\n|\r','');


return



%% Could make it smarter to allow for multiple file types, etc...
% tn  = tempname;
% cmd = ['find ' path ' -follow -type f -name "' fileName '" | tee ' tn];
% 
% [status, result] = system(cmd);
% 
% if status ~= 0
%     error('There was a problem finding files.');
% end
% 
% % WORK HERE - if tn is empty then we need to not follow through
% 
% % niFiles will now have a full-path list of all relevant files
% if ~isempty(result)
%     theFiles = readFileList(tn);
% else
%     disp('no files found');  
%     return
% end