function ncores = vistaGetNumCores(varargin)
%
% ncores = vistaGetNumCores
% 
%  Returns the number of cores available on the
%  system. Useful when initializing a parallel pool.
%
% INPUTS: 
%   <none>
%
% OUTPUTS: 
%   ncores = The total number of threads on the machine. Type = [double]. 
% 
% 
% (C) Stanford University, VISTA Lab, 2015
% 


%% Hande input/output

% Handle any inputs
if nargin > 0
    disp('This function does not take inputs. They will be ignored.');
end

% Initialize the output
ncores = '';


%% Get/Return the number of cores

% Do things differently depending on sysarch.
if ismac  
    [stat, ncores] = system('sysctl hw.ncpu | awk ''{print $2}''');
elseif isunix
    [stat, ncores] = system('nproc');
elseif ispc
    fprintf('Unable to set number of cores for %s\n', computer);
    stat = 1;
end

% If command was successful convert the string to a number
if stat == 0
    ncores = str2double(ncores);
else
    fprintf('Number of cores could not be determined.\n');
end

return