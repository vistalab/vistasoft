function [status, results] = mrtrix_dwi2tensor (in_file, out_file, b_file, verbose)

%
% Calculate diffusion tensors. 
%
% Parameters
% ----------
% in_file: The name of a diffusion file in .mif format
% out_file: The name of the resulting dti file in .mif format
% b_file: The name of a mrtrix format gradient vector file (default: 'encoding.b')
%
% Returns
% -------
% status: whether (0) or not (1) the operation succeeded 
% results: the results of the operation in the terminal
%
% Notes
% -----
% http://www.brain.org.au/software/mrtrix/tractography/preprocess.html


if notDefined('verbose')
   verbose = true; 
end

if notDefined('bkgrnd')
   bkgrnd = false; 
end


if notDefined('b_file')
    b_file = 'encoding.b';
end 

% This command generates  tensors: 
cmd_str = sprintf('dwi2tensor %s %s -grad %s',in_file, out_file, b_file); 

% Send it to mrtrix: 
[status,results] = mrtrix_cmd(cmd_str, bkgrnd, verbose); 