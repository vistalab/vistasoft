function file = mrvFindFile(fileName,directory)
% 
%  file = mrvFindFile(fileName,directory)
% 
% This simple function is designed to find a return a full path to a given
% file within a directory. It will search the directory tree recursively to
% find the file and give you it's full path. 
% 
% EXAMPLE:
%   
% file = mrvFindFile(pwd, 'dt6.mat')
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

[ p, ~ ] = fileparts(directory);
if isempty(p)
    directory = fullfile(pwd,directory);
end

file = '';

cmd = ['find ' directory ' -follow -type f -name "' fileName '"'];

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