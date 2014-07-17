function [status,results] = mrtrix_cmd(cmd_str, bkgrnd, verbose)
% function [status,results] = mrtrix_cmd(cmd_str, [bkgrnd=true], [verbose=true])
%
% Send a command to an mrtrix function and get back status and results
%
% INPUTS:
%   cmd_str - A string containing the mrtrix command to run
%   bkgrnd  - [true/false] Whether to execute the command in the background (only possible on unix)
%   verbose - Whether to display stdout to the command window (when it's done).
%
% OUTPUTS:
%   status  - Whether the operation succeeded (1) or not (0)
%   results - The results of the operation in stdout.
%
% Notes:
%  When bkgrnd is set to true, the command will be executed in another
%  terminal.
%
%
% Franco Pestilli, Ariel Rokem & Bod Dougherty Stanford Univesity

if notDefined('bkgrnd'), bkgrnd = false;end
if notDefined('verbose'),verbose = true;end

% Need to bypass the matlab libraries at the top of the path, by screwing
% with it:
orig_ld_path = mrtrix_set_ld_path;

% This opens another xterm, runs it there and gives you back control of the
% matlab session:
if bkgrnd
    if ~isunix
        bkgrnd = false;
        warning('Cannot run in background on MS Windows. Defaulting to run mrtrix command in the Matlab session');
    else
        cmd_str = ['xterm -e ' cmd_str ' &'];
    end    
end
fprintf('\n[%s] Running the following command: \n%s\n',mfilename,cmd_str); 

% Run the command and get back status and results:
[status,results] = system(cmd_str);

% If there was a failure, throw a warning:
if (status ~=0)
    warning('[%s] There was a failure running the command. \nCommand: %s\nError %s\n',mfilename,results);
end

% If running the command within the matlab session and verbose, display
% results, when it returns:
if (~bkgrnd && verbose), disp(results); end

% Reset the ld_path:
setenv('LD_LIBRARY_PATH', orig_ld_path);

end
