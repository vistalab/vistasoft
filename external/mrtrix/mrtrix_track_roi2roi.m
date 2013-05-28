function [pdb_file, status, results] = mrtrix_track_roi2roi(files, roi1, roi2, seed, mask, mode, n, n_max, bkgrnd, verbose)

% Provided a csd estimate, generate estimates of the fibers starting in the
% seed region, touching both roi1 and roi2.
%
% Parameters
% ----------
% files: structure, containing all the filenames generated with
%        mrtrix_init.m.
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
% Franco, Bob & Ariel (c) Vistalab Stanford University 2013

if notDefined('verbose'),verbose = true; end
if notDefined('bkgrnd'), bkgrnd = false; end
if notDefined('clobber'), clobber = false;end

% Choose the tracking mode (probabilistic or stream)
switch mode
  case {'prob','probabilistic','probabilistic tractography','p'}
    mode_str = 'SD_PROB';
  case {'stream','deterministic','deterministic tractography based on spherical deconvolution','d'}
    mode_str = 'SD_STREAM';
  case {'tensor','deterministic tractography based on a tensor model','t'}
    mode_str = 'DT_STREAM';
  otherwise
    error('Input "%s" is not a valid tracking mode', mode); 
end

% Track, using deterministic estimate: 
tck_file = strcat(strip_ext(files.csd), '_' , strip_ext(roi1), '_', strip_ext(roi2), '_', ...
                            strip_ext(seed) , '_', strip_ext(mask), '_', mode, '.tck'); 
                          
% Generate a UNIX command string.                          
switch mode_str
  case {'SD_PROB', 'SD_STREAM'}
    cmd_str = sprintf('streamtrack -seed %s -mask %s -include %s -include %s %s %s %s -number %d -maxnum %d -stop',...
      seed,mask, roi1, roi2, mode_str, files.csd, tck_file, n, n_max);
    % The following lines of code could be intergated here, to allow for
    % tracking between ROIs using a tensor-based deterministic tractography
    %   case {'DT_STREAM'}
    %       cmd_str = sprintf('streamtrack -seed %s -mask %s -include %s -include %s %s %s %s -number %d -maxnum %d -stop',...
    %       seed, mask, roi1, roi2, mode_str,files.csd, tck_file, n, n_max);
    %
    %     [~, pathstr] = strip_ext(files.dwi);
    %     tck_file = fullfile(pathstr,strcat(strip_ext(files.dwi), '_' , strip_ext(roi), '_',...
    %       strip_ext(mask) , '_', mode, '-',num2str(nSeeds),'.tck'));
    %
    %     % Generate the mrtrix-unix command.
    %     cmd_str = sprintf('streamtrack %s %s -seed %s -grad %s -mask %s -include %s -include %s %s -num %d', ...
    %                                 mode_str, files.dwi, roi, files.b, mask, roi1, roi2,  tck_file, nSeeds);

  otherwise
    error('Input "%s" is not a valid tracking mode', mode_str);
end

% Launch the command
if ~(exist(tck_file,'file') ==2)  || clobber == 1  
    [status, results] = mrtrix_cmd(cmd_str, bkgrnd, verbose);
else
  fprintf('\nFound fiber tract file: %s.\n Loading it rather than retracking',tck_file)
  status = 0;
  results = 'loaded file from disk';
end

% Convert the tracks to pdb format:
pdb_file = strcat(strip_ext(tck_file), '.pdb');
mrtrix_tck2pdb(tck_file, pdb_file);

end 

% Why does everything have to be so hard? 
function no_ext = strip_ext(file_name)

[pathstr, no_ext, ext] = fileparts(file_name); 

end