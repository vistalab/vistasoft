function [cmd, outFile] = ctrScript(p,sName,outFile, outFileType)
%Create unix script to run ConTrack fiber generation
%
%   [cmd, outFile] = ctrScript(p,[sName],outFile, [outFileType])
%
% This saves the bash script used to run ConTrack.  The script is saved in
% the dt6 file directory.  The other files used by this script are located
% relative to this directory in the fibers\contrack directory.
%
% The usage for the Contrack fiber generation program is:
%
% USAGE: 
%    ./contrack_gen.glxa64  -i <string> -p <string> [-t <float>] [-A] [-v]
%                           [--] [--version] [-h]
% Where: 
%    -i <string>,  --info <string>
%      (required)  Information file, e.g. met_params.txt.
%    -p <string>,  --pdb <string>
%      (required)  Pathway database output file, e.g. paths.Bfloat.
%    -t <float>,  --time <float>
%      Pathway generation time limit.(EXPERIMENTAL--DON'T USE!!)
%    -A,  --Axial
%      Axial pathway generation.(EXPERIMENTAL--DON'T USE!!)
%    -v,  --vox
%      Voxelwise pathway generation.(EXPERIMENTAL--DON'T USE!!)
%    --,  --ignore_rest
%      Ignores the rest of the labeled arguments following this flag.
%    --version
%      Displays version information and exits.
%    -h,  --help
%      Displays usage information and exits.
%
%    ConTrack's pathway generation algorithm.
%
% Example:
%   sName = 'myScript.sh';
%   outFile = 'myTestFibers';
%   outFileType = 'pdb';
%   [cmd, outFile] = ctrScript(p,sName,outFile,outFileType)
%
% Author: AJS, BW
% 2008.09.17 DY & MP Edited the CMD to remove nohup and logFile to deal with
% errors running the command with Cygwin. These are not essential to
% running conTrack.
% 2008.12.04 DY&MP added the system command (chmod) to change the
% permissions of the .sh file (sName). 
% 2009.03.10 GS & DY: add option to output pdb-format fiber files rather
% than Bfloat. added optional third input argument OUTFILETYPE, which
% defaults to Bfloat.
% 2009.06.11 DY: removed the '&' on the last line of the .sh file, which
% allows control over which processes are run in the background or not at
% the batch scripting level

if notDefined('p'), error('Parameters needed'); end

if notDefined('sName'), 
    sName = ['ctrScript_',p.timeStamp,'.sh']; 
    sName = fullfile(p.localSubjDir,'fibers','conTrack',sName);
end

if notDefined('outFileType')
    outFileType = '.pdb';  % should be .pdb
elseif outFileType(1) ~= '.'
    outFileType = ['.' outFileType];
end

if notDefined('outFile'),
    [tmp,roi1] = fileparts(p.roi1File);
    [tmp,roi2] = fileparts(p.roi2File);
    outFile = [roi1,'_',roi2,'_',p.timeStamp,outFileType];
end



% We create a relative path to the sampler file.  It is stored in the
% ..\fibers\contrack directory
[tmp,samplerFile,ext] = fileparts(p.samplerFile);
samplerFile = [samplerFile,ext];

% Get the log file text name. 
[tmp,logFile,ext] = fileparts(p.logFile);
logFile = [logFile,ext];

% Create script for fiber generation 
fid = fopen(sName,'wt');

% We write out an executiable bash script.  We write the script in the
% ..\fibers\contrack directory and we assume the user executes the script
% from inside the dt6 directory.  The output fiber file will be written to
% the ..\fibers\contrack directory.  The parameters file is also in the
% ..\fibers\contrack directory.
if ismac
    contrackBin = which('contrack_gen.maci64');
else % assume linux
    contrackBin = which('contrack_gen.glxa64');
end

fprintf(fid,'#!/bin/bash\n');
% cmd = sprintf('CMD=''nohup %s -i %s -p %s >%s;''',contrackBin,samplerFile,outFile,logFile);
cmd = sprintf('CMD=''%s -i %s -p %s''',contrackBin,samplerFile,outFile);
fprintf(fid,'%s \n',cmd);
fprintf(fid,'echo $CMD\n');
fprintf(fid,'$CMD\n');
fclose(fid);

% Edit permissions of the .sh file (sName) so that it can be executed.
[status,result] = system(['chmod 775 ' sName]);
if status ~= 0
    disp(['chmod failure in ctrScript Line 88: Permissions need to be edited manually for ' sName]);
end

return;