function [status, results] = mrtrix_track_roi2roi(csd, roi1, roi2, seed, mask, mode, n, n_max, bkgrnd, verbose)

% Provided a csd estimate, generate estimates of the fibers starting in the
% seed region, touching both roi1 and roi2.
%
% Parameters
% ----------
% csd: string, filename for an mrtrix CSD estimate
% roi1: string, filename for a .mif format ROI file (mask).  
% roi2: string, filename for a .mif format ROI file (mask). 
% seed: string, filename for a .mif file contain part of the image in which
%       to place the seeds. 
% mask: string, filename for a .mif format of a mask.
% mode: Tracking mode: {'prob' | 'stream'} for probabilistic or
%       deterministic tracking. 
% n: The number of fibers to select.
% n_max: The number of fibers to generate, often need more than the
%        defaults (which is 100 x n). 
% bkgrnd: on unix, whether to perform the operation in another process
% verbose: whether to display stdout to the command window. 
% 
if notDefined('verbose')
    verbose = true;
end

if notDefined('bkgrnd')
    bkgrnd = false;
end
% Choose the tracking mode (probabilistic or stream)
if strcmp(mode,'prob')
    mode_str = 'SD_PROB';
elseif strcmp(mode,'stream')
    mode_str = 'SD_STREAM';
else
    error(sprintf('Input "%s" is not a valid tracking mode', mode)); 
end

% Track, using deterministic estimate: 
tck_file = strcat(strip_ext(csd), '_' , strip_ext(roi1), '_', strip_ext(roi2), '_', ...
                            strip_ext(seed) , '_', strip_ext(mask), '_', mode, '.tck'); 
                             
cmd_str = sprintf('streamtrack -seed %s -mask %s -include %s -include %s %s %s %s -number %d -maxnum %d -stop',...
                seed, mask, roi1, roi2, mode_str, csd, tck_file, n, n_max); 
                
[status, results] = mrtrix_cmd(cmd_str, bkgrnd, verbose);

% Convert to pdb:
pdb_file = strcat(strip_ext(tck_file), '.pdb');
mrtrix_tck2pdb(tck_file, pdb_file);

end 

% Why does everything have to be so hard? 
function no_ext = strip_ext(file_name)

[pathstr, no_ext, ext] = fileparts(file_name); 

end