function [status, results] = mrtrix_csdeconv(dwi_file, response_file, lmax, ...
                                   out_file, grad_file, mask_file, verbose)

%function [status, results] = mrtrix_csdeconv(dwi_file, response_file, lmax, ...
%           out_file, grad_file, [mask_file=entire volume], [verbose=true])
%
% Fit the constrained spherical deconvolution model to dwi data 
%
% Parameters
% ----------
% dwi_file: The name of a dwi file in .mif format. 
% response_file: The name of a .txt fiber response function file. 
% lmax: The maximal harmonic order. 
% out_file: The resulting .mif file. 
% grad_file: a file containing gradient information in the mrtrix format. 
% mask_file: a .mif file containing a mask. Default: the entire volume. 
% verbose: Whether to display stdout to the command window. 
% 
% Returns
% -------
% status: whether (0) or not (1) the operation succeeded
% results: the results of the operation in stdout
%
% Notes
% -----
% http://www.brain.org.au/software/mrtrix/tractography/preprocess.html
% 

if notDefined('verbose')
    verbose = true; 
end

if notDefined('bkgrnd')
    bkgrnd = false;
end

if notDefined('mask_file')
cmd_str = sprintf('csdeconv %s %s -lmax %d %s -grad %s',...
    dwi_file, response_file, lmax, out_file, grad_file);

else 
cmd_str = sprintf('csdeconv %s %s -lmax %d -mask %s %s -grad %s',...
    dwi_file, response_file, lmax, mask_file, out_file, grad_file);
end 

[status,results] = mrtrix_cmd(cmd_str, bkgrnd, verbose);
