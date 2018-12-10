function [status, results, fg, pathstr] = mrtrix_track(files, roi, mask, mode, nSeeds, curvature, cutoff, bkgrnd, verbose, clobber)
%
% function [status, results, fg, pathstr] = mrtrix_track(files, roi, mask, mode, nSeeds, bkgrnd, verbose)
%
% Provided a csd estimate, generate estimates of the streamlines/fascicles starting in roi 
% and terminating when they reach the boundary of mask
%
% Parameters
% ----------
% files: structure, containing the filenames generated using mrtrix_init.m
% roi: string, filename for a .mif format file containing the ROI in which
%      to place the seeds. Use the *_wm.mif file for Whole-Brain
%      tractography.
% mask: string, filename for a .mif format of a mask. Use the *_wm.mif file for Whole-Brain
%      tractography.
% mode: Tracking mode: {'prob' | 'stream'} for probabilistic or
%       deterministic tracking. 
% nSeeds: The number of fibers to generate.
% curvature: The minimum radius of curvature required for tractography
%            (default is 2 for DT_STREAM, 0 for SD_STREAM, 1 for
%            SD_PROB)
% cutoff: The stopping criteria for tractography based on FA (DT_STREAM)
%           or FOD amplitude cutoff (CSD tracking).  
% bkgrnd: on unix, whether to perform the operation in another process
% verbose: whether to display standard output to the command window. 
% clobber: Whether or not to overwrite the fiber group if it was already
%          computed
% 
% Log
% 2013 Franco, Bob & Ariel wrote the function
% 2015 Dec Hiromasa modified function for generarization to ET project
% (c) Vistalab Stanford University 2013 

status = 0; results = [];
if notDefined('verbose'),  verbose = false;end
if notDefined('bkgrnd'),    bkgrnd = false;end
if notDefined('clobber'),  clobber = false;end
if notDefined('cutoff'),  cutoff = 0.1;end

% Choose the tracking mode (probabilistic or stream),
% and set default tracking parameter unless specified
switch mode
    case {'prob','probabilistic tractography'}
        mode_str = 'SD_PROB';
        if notDefined('curvature'),  curvature = 1;end
    case {'stream','deterministic tractogrpahy based on spherical deconvolution'}
        mode_str = 'SD_STREAM';
        if notDefined('curvature'),  curvature = 0;end
    case {'tensor','deterministic tractogrpahy based on a tensor model'}
        mode_str = 'DT_STREAM';
        if notDefined('curvature'),  curvature = 2;end
        
    otherwise
        error('Input "%s" is not a valid tracking mode', mode);
end

% Generate a UNIX command string.                          
switch mode_str
  case {'SD_PROB', 'SD_STREAM'}
    % Build a file name for the tracks that will be generated.
    % THe file name will contain information regarding the files being used to
    % track, mask, csd file etc.
    [~, pathstr] = strip_ext(files.csd);
    tck_file = fullfile(pathstr,strcat(strip_ext(files.csd), '_' , strip_ext(roi), '_',...
      strip_ext(mask) , '_', mode, '-curv',num2str(curvature),'-cutoff',num2str(cutoff),'-',num2str(nSeeds),'.tck'));
    
    % Generate the mrtrix-unix command.
    cmd_str = sprintf('streamtrack %s %s -seed %s -mask %s -curvature %s -cutoff %s %s -num %d', ...
                                mode_str, files.csd, roi, mask, num2str(curvature), num2str(cutoff), tck_file, nSeeds); 
    
  case {'DT_STREAM'}
          % Build a file name for the tracks that will be generated.
    % THe file name will contain information regarding the files being used to
    % track, mask, csd file etc.
    [~, pathstr] = strip_ext(files.dwi);
    tck_file = fullfile(pathstr,strcat(strip_ext(files.dwi), '_' , strip_ext(roi), '_',...
      strip_ext(mask) , '_', mode, '-curv',num2str(curvature),'-cutoff',num2str(cutoff),'-',num2str(nSeeds),'.tck'));
              
    % Generate the mrtrix-unix command.
    cmd_str = sprintf('streamtrack %s %s -seed %s -grad %s -mask %s -curvature %s -cutoff %s %s -num %d', ...
                                mode_str, files.dwi, roi, files.b, mask, num2str(cutoff), num2str(cutoff), tck_file, nSeeds); 

  otherwise
    error('Input "%s" is not a valid tracking mode', mode_str);
end

% Track using the command in the UNIX terminal
if ~(exist(tck_file,'file') ==2)  || clobber == 1
    [status, results] = mrtrix_cmd(cmd_str, bkgrnd, verbose);
else
  fprintf('\nFound fiber tract file: %s.\n Loading it rather than retracking',tck_file)
end

% Convert the .tck fibers created by mrtrix to mrDiffusion/Quench format (pdb):
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