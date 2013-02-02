function [status, results, fg, pathstr] = mrtrix_track(csd, roi, mask, mode, nSeeds, bkgrnd, verbose, clobber)
%
% function [status, results, fg, pathstr] = mrtrix_track(csd, roi, mask, mode, nSeeds, bkgrnd, verbose)
%
% Provided a csd estimate, generate estimates of the fibers starting in roi 
% and terminating when they reach the boundary of mask
%
% Parameters
% ----------
% csd: string, filename for an mrtrix CSD estimate
% roi: string, filename for a .mif format file containing the ROI in which
%      to place the seeds. Use the *_wm.mif file for Whole-Brain
%      tractography.
% mask: string, filename for a .mif format of a mask. Use the *_wm.mif file for Whole-Brain
%      tractography.
% mode: Tracking mode: {'prob' | 'stream'} for probabilistic or
%       deterministic tracking. 
% nSeeds: The number of fibers to generate.
% bkgrnd: on unix, whether to perform the operation in another process
% verbose: whether to display standard output to the command window. 
% clobber: Whether or not to overwrite the fiber group if it was already
%          computed
% 
status = 0; results = [];

if notDefined('verbose')
    verbose = false;
end

if notDefined('bkgrnd')
    bkgrnd = false;
end
if notDefined('clobber')
    clobber = false;
end
% Choose the tracking mode (probabilistic or stream)
if strcmp(mode,'prob')
    mode_str = 'SD_PROB';
elseif strcmp(mode,'stream')
    mode_str = 'SD_STREAM';
end

% Track, using deterministic estimate:
[~, pathstr] = strip_ext(csd);
tck_file = fullfile(pathstr,strcat(strip_ext(csd), '_' , strip_ext(roi), '_',...
                            strip_ext(mask) , '_', mode, '-',num2str(nSeeds),'.tck')); 

if ~(exist(tck_file,'file') ==2)  || clobber == 1
  
    cmd_str = sprintf('streamtrack %s %s -seed %s -mask %s %s -num %d', ...
                                 mode_str, csd, roi, mask, tck_file, nSeeds); 

    [status, results] = mrtrix_cmd(cmd_str, bkgrnd, verbose);
else
  fprintf('\nFound fiber tract file: %s.\n Loading it rather than retracking',tck_file)
end

% Convert to pdb:
pdb_file = fullfile(pathstr,strcat(strip_ext(tck_file), '.pdb'));
fg = mrtrix_tck2pdb(tck_file, pdb_file);

end 

%%%%%%%%%%%%%
% strip_ext %
%%%%%%%%%%%%%
function [no_ext pathstr] = strip_ext(file_name)
%
% Removes the extension of the files, plus returns the path to the files.
%
[pathstr, no_ext, ext] = fileparts(file_name); 

end