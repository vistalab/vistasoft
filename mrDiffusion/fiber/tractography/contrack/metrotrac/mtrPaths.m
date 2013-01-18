function fg = mtrPaths(mtr, xform, samplerOptsFile, fgFile, samplerLogFile)
% Generate MetroTrac (mtr) pathways.
%
%  fg = mtrPaths(mtr, dt.xformToAcPc, samplerOptsFile, fgFile)
%
% Calls the executable.  Only the Windows version currently is compiled at
% present.
%
% The fiber returned are in the format used by dtiFiberUi.  These could be
% written directly in a script into the fibers directory.  In addition, an
% output file is written into the bin/metrotrac directory in the .dat
% format.  That file can be imported into dtiFiberUI from the pull down
% menus in File.
% 

% Write params file out because we are going to run a separate executable
mtrSave(mtr,samplerOptsFile,xform);

% Run metrotrac
%% Check environment we are running in
if(ispc)
    executable = which('dtiprecompute_met.exe');
elseif(strcmp(computer,'GLNXA64'))
    executable = which('dtiprecompute_met.glxa64');
else
    error('Not compiled for %s.',computer);
end

%% Run the executable
args = sprintf(' -i %s -p %s', samplerOptsFile, fgFile);
cmd = [executable args];
disp(cmd); disp('...')
[s, ret_info] = system(cmd,'-echo');
disp('Done')

%% Write out command line output from program
if (~ieNotDefined('samplerLogFile'))
    save(samplerLogFile,'ret_info','-ASCII');
end

%% Import the resulting fiber group
fg = mtrImportFibers(fgFile, xform);

return;
