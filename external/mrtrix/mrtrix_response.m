function [status,results] = mrtrix_response(mask_file, fa_file, sf_file,...
                                            dwi_file, response_file, b_file,...
                                            threshold, show_figure, bkgrnd,  ...
                                            lmax, verbose)
% Calculate the fiber response function utilized by MRtrix for the spherical
% deconvolution analysis.
%
% INPUTS
%     mask_file - The name of a mask file in .mif format
%       fa_file - The name of an FA map file in .mif format
%       sf_file - The name of a generated sf file (with areas of high anisotropy
%                 and presumably single fibers)
%      dwi_file - The name of a .mif file with dwi data 
% response_file - The name of a generated file with the response function (.txt)
%        b_file - The name of a .mif file with an mrtrix format gradient file
%     threshold - A string containing the type of thresholding to be
%                 applied to the white-matter mask to identify the areas of
%                 strong anisotropy. The default is to use the absolute
%                 value of FA, -abs 0.8. Alternatively it is possible to use
%                 other methods allowed by the mrtrx 'threshold'
%                 In a unix shell type the followin for more information: 
%                 $threshold --help
%                 Possible alternative:
%                   '-percent .8' % thresholding defined as percent FA
%   show_figure - Optional. Whether to show a figure of the response function
%                 profile (default: true)
%       verbose - Outputs the opretions being performted in the MatLab
%                 prompt.
% 
% OUTPUTS
%        status - whether (0) or not (1) the operation succeeded
%       results - the results of the operation in the terminal
%
% NOTES
% http://www.brain.org.au/software/mrtrix/tractography/preprocess.html
%
% Franco Pestilli, Bob Dougherty and Ariel Rokem, Stanford University
if notDefined('verbose'), verbose = true;end
if notDefined('bkgrnd'),   bkgrnd = false;end
if notDefined('lmax'),       lmax = 6;end
if notDefined('threshold'),  threshold = '-abs 0.8';end

% This generates a mask of voxels with high FA. These are assumed to be
% voxels that contain a single fiber:
cmd_str = sprintf('erode %s - | erode - - | mrmult %s - - | threshold - %s %s',...
    mask_file, fa_file, threshold, sf_file);
[status, results] = mrtrix_cmd(cmd_str, bkgrnd, verbose);

if ~status
    % Once we know where there are single fibers, we estimate the fiber
    % response function from these voxels:
    cmd_str = sprintf('estimate_response %s %s %s -grad %s -lmax %i',...
        dwi_file, sf_file, response_file, b_file, lmax);
    [status, results] = mrtrix_cmd(cmd_str, bkgrnd, verbose);
    
    if ~status
        % We can take a look at this. It should look like a disk (see the figure
        % example in
        % http://www.brain.org.au/software/mrtrix/tractography/preprocess.html):
        if show_figure
            cmd_str = sprintf('disp_profile -response %s &',response_file);
            mrtrix_cmd(cmd_str, false, verbose);
        end
    end
end

end