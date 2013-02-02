function [status,results] = mrtrix_wm_mask(dwi_file, mask_file, out_file,  wm_th, verbose)

% function [status,results] = mrtrix_wm_mask(dwi_file, mask_file, out_file, ...
%     [wm_th=0.4], [verbose=true])
% 
% Generate a white-matter mask
% 
% Parameters
% ----------
% dwi_file: mrtrix .mif file with dwi data
% mask_file: A brain-mask file in .mif format
% out_file: The generated white-matter mask file name
% wm_th: optional, the threshold value to use for thresholding the white
%        matter
% 
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

if notDefined('wm_th')
    wm_th = 0.4; 
end

if wm_th == 0
    cmd_str = sprintf('gen_WM_mask %s %s %s -grad %s', ...
        dwi_file, mask_file, out_file, grad_file);
    
    [status, results] = mrtrix_cmd(cmd_str);
    
% If a non-zero threshold is defined, perform an intermediate step of generating a
% temporary wm file and then an additional step of thresholding to get the
% final result: 
else
    temp_wm = sprintf('%s%s',tempdir,'wm_tmp');
    cmd_str1 = sprintf('gen_WM_mask dwi.mif mask.mif %s -grad %s',dwi_file ,mask_file, temp_wm, grad_file);
    cmd_str2 = sprintf('threshold %s %s -abs %d',temp_wm, out_file, wm_th);
    
    [status, results] = mrtrix_cmd(cmd_str1);
    [status, results] = mrtrix_cmd(cmd_str2);
end
