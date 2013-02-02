function [status,results] = mrtrix_brainmask_generate(in_file, out_file, verbose)

%
% Generate a brain mask in .mif format from a diffusion file in .mif format
% 
% Parameters
% ----------
% in_file: string, full-path to a dwi file from which the   
% out_file: the name of the resulting brain-mask file
% 
% Returns
% -------
% status: return value from the system call; 0 (success), non-zero
% (failure)
% results: the results of the operation in stdout
%
% Notes 
% ----- 
% http://www.brain.org.au/software/mrtrix/tractography/preprocess.html
%
% 

if notDefined('verbose')
    verbose = true; 
end

% This command string generates a brain-mask (quite liberal):
cmd_str = sprintf('mrconvert %s -coord 3 0 - | threshold - - | median3D - - | median3D - %s',...
                  in_file, out_file);

% Send the command to mrtrix: 
[status, results] = mrtrix_cmd(cmd_str, verbose);
 