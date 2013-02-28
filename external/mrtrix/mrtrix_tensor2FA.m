function [status, results] = mrtrix_tensor2FA(in_file, out_file, mask_file, verbose)

%
% Calculate diffusion tensors.
%
% Parameters
% ----------
% in_file: The name of a dti file in .mif format
% out_file: The name of the resulting fa file in .mif format
% mask_file: The name of a mask file in .mif format (default to the entire
%             volume). 
% 
% Returns
% -------
% status: whether (0) or not (non-zero) the operation succeeded
% results: the results of the operation in stdout
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

% If no mask file was provided, calculate this over the entire volume
if notDefined('mask_file')
    cmd_str = sprintf('/usr/lib/mrtrix/bin/tensor2FA %s %s', in_file, out_file);
% Otherwise, use the mask file provided: 
else
    cmd_str = sprintf('/usr/lib/mrtrix/bin/tensor2FA %s - | mrmult - %s %s', in_file, mask_file, out_file);
end

% Send it to mrtrix:
[status,results] = mrtrix_cmd(cmd_str, bkgrnd, verbose);