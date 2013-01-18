function [mexFiles cFiles status params] = mrvCompile(deleteOldFiles, findCFiles)
% Compile all MEX files in VISTASOFT for a given MATLAB installation.
% 
% [mexFiles cFiles status params] = mrvCompile([deleteOldFiles=0], [findCFiles=0]);
%
% This function detects the current OS, CPU architecture, and MATLAB
% version on which it is being run, and compiles all C files into the
% appropriate format MEX files. 
% 
% INPUTS:
%	deleteOldFiles: flag to delete other existing binary MEX files. If 1,
%	will delete any existing compiled files, preventing namespace confusion
%	with the new compiled code. Delete at your own risk. [default 0, don't
%	delete.]
%
%	findCFiles: flag to search through the VISTASOFT repository for all C
%	files. By default this is 0, since a list of C files (as of October
%	2008) is hard-coded into this function. However, if someone has added
%	new C files, this flag will direct the code to search for them and add
%	them to the compile list.
%	
% OUTPUTS:
%	mexFiles: cell array of paths to each compiled mex file. Empty if the
%	attempt to compile was unsuccessful.
%
%	cFiles: cell array of paths to each source-code (*.c) file that the
%	function attempted to compile.
%
%	status: 1 x N vector, where N is the number of C files, indicating
%	which ones compiled successfully.
%
%	params: structure with information about the OS, MATLAB version,
%	architecture, and any other relevant information, as well as any error
%	messages generated during the compile code.
%
% Author: ras, 10/2008. To be completed by Santhosh Kassavajjala, autumn
% 2008.
%
% TODO:
%  Allow extra libs to be included. E.g., on some systems, we need to
% explicitly add libz. E.g., the following is needed to compile the nifti
% mex files on a Linux installation.
%
%   cd(fileparts(which('readFileNifti.c')))
%   eval(['mex matToQuat.c nifti1_io.c znzlib.c ' matlabroot '/bin/glnxa64/libz.so.1']);
%   eval(['mex readFileNifti.c nifti1_io.c znzlib.c ' matlabroot '/bin/glnxa64/libz.so.1']);
%   eval(['mex writeFileNifti.c nifti1_io.c znzlib.c ' matlabroot '/bin/glnxa64/libz.so.1']);
%
%  We should have instructions about adding VTK libraries for the mesh
%  compiles, as well.  
% (c) Stanford VISTA Team 2008

if notDefined('deleteOldFiles'),	deleteOldFiles = 0;		end
if notDefined('findCFiles'),		findCFiles = 0;			end

% determine parameters that will affect compiling
% this includes OS, architecture, MATLAB version, ...?
params = getInstallationParams;

% get a list of the C files to compile
cFiles = getCFileList(findCFiles, params.rootPath);

% clean old files if necessary
if deleteOldFiles==1
	deleteExistingMexFiles(params.rootPath);
end

% TO ADD: check if we have the right compiler...
params = checkMexSetup(params);

% Main part: compile all files
[mexFiles, status, params] = compileCFiles(cFiles, params);

return
% /--------------------------------------------------------------/ %



% /--------------------------------------------------------------/ %
function cFiles = getCFileList(findCFiles, rootPath)
% return a cell array of paths to *.c source files. 
% If findCFiles==1, do a recursive search to generate this list. Otherwise,
% use a preset list.
if findCFiles==1
	% recursive search: not yet implemented
	error('Find C files not yet impelemented.');
else
	cFiles = defaultCFileList;
	% append each path to the location of the root VISTASOFT repository:
	for ii = 1:length(cFiles)
		cFiles{ii} = fullfile(rootPath, cFiles{ii});
        if(~isempty(strfind(cFiles{ii},';')))
           cFiles{ii} = strrep(cFiles{ii}, ';', [' ' rootPath filesep]);
        end
	end
end
return
% /--------------------------------------------------------------/ %



% /--------------------------------------------------------------/ %
function params = getInstallationParams
% returns a structure with info on the current MATLAB / VISTASOFT setup.
% parent directory of the local VSITASOFT repository (/trunk of code)
params.rootPath = fileparts(mrvRootPath);

% MATLAB version params
params.matlabVersion = ver('Matlab');
params.matlabVersion.Version = str2num(params.matlabVersion.Version);
params.preferredMexExtension = mexext;
params.allowedMexExtensions = mexext('all');

% Computer / OS params
if ispc
	params.os = 'PC';
elseif ismac
	params.os = 'Mac';
elseif isunix
	params.os = 'Unix';
else
	warning( sprintf('Unknown operating system %s. Compiling may not work...', computer) )
	params.os = 'Other';
end
params.computerType = computer;

% check for 64-bit architecture
if strncmp(params.computerType(end-1:end), '64', 2)==1
	params.is64Bit = 1;
else
	params.is64Bit = 0;
end
params.architecture = computer('arch');

% parameters for how to proceed with the compiling:
% how verbose should the compiling output be?
params.verbose = prefsVerboseCheck;

% Do we want to create a log file with symbolic information for debugging?
params.makeLogFile = 0;
	
% initialize an empty field for keeping track of files with errors, and
% error messages:
params.filesWithErrors = {};
params.errorMessages = struct('message', '', 'identifier', [], 'stack', '');
params.errorMessages = params.errorMessages([]); % empty struct

return
% /--------------------------------------------------------------/ %



% /--------------------------------------------------------------/ %
function deleteExistingMexFiles(rootPath)
% Search through the root VISTASOFT repository, finding all MEX files that
% MATLAB might attempt to execute, and delete them. This prevents these
% files from conflicting with the new compiled files we will create.
warning('deleteExistingMexFiles Not yet implemented.')
return
% /--------------------------------------------------------------/ %



% /--------------------------------------------------------------/ %
function params = checkMexSetup(params)
% checks if we have the proper compiler / other parameters for running
% the MEX command successfully. This includes libraries. If the right
% compiler is missing, should offer the user the chance to download them,
% then proceed.

% add stuff here...
% mex -setup

fprintf('\t*** [%s] ***\n', mfilename);
fprintf('\tCompiling MEX files. Beginning at %s.\n', datestr(now));
return
% /--------------------------------------------------------------/ %



% /--------------------------------------------------------------/ %
function [mexFiles, status, params] = compileCFiles(cFiles, params)
% main function: run through a list of C-files, and try to compile them.
for ii = 1:length(cFiles)
	try
		fprintf('[%s]: Trying to compile %s... (%s)\n', mfilename, ...
				cFiles{ii}, datestr(now));
		eval(['mex ' cFiles{ii}]);
	
		fprintf('[%s]: Completed call to MEX.\n', mfilename);
		
		% did it succeed? 
		% For now, we check whether the appropriate MEX file exists. Very soon,
		% we should actually test the MEX code, using mrvMexTest.
		[p f ext] = fileparts(cFiles{ii});
		mexFiles{ii} = fullfile(p, [f '.' params.preferredMexExtension]);
		if exist(mexFiles{ii}, 'file')
			status(ii) = 1;
		else
			status(ii) = 0;
		end
		% status(ii) = mrvMexTest(mexFiles{ii});
	catch
		status(ii) = 0;
		params.filesWithErrors{end+1} = cFiles{ii};
		params.errorMessages(end+1) = lasterror;
	end
end
return
