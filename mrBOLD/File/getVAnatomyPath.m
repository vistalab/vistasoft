function [pth, anatDir, subject] = getVAnatomyPath(varargin)
%
% [pth, anatDir, subject] = getVAnatomyPath;
%
% Gets path of a given subject's volume anatomy. No longer takes any
% input arguments (ignores them all): Just does 2 things:
%
% (1) checks if the path is saved in mrSESSION.mat. If the variable
% vANATOMYPATH is saved in this file, and the path it specifies exists,
% we're done;
%
% (2) if mrSESSION.mat doesn't exist, the variable isn't defined, or the
% path isn't found, looks for a single alternate possibility: the file
% vAnatomy.dat in the subject's anatomy directory. 
%
% If these two options don't work, the code prompts the user to find the
% file.
%
% ras, 06/2008: restarted because the old code was becoming a mess again. 

% programming note: I make the output argument "pth" distinct from
% vANATOMYPATH because of global variable issues. I want to allow the global
% variable vANATOMYPATH (which is saved on disk) to be specified as a
% relative path (e.g. a link), while the local variable (used by whatever
% is accessing this function) to reflect a full path. This satisfies two
% constraints:
% (1) The variable saved on disk makes sense whether you access that file from
% a unix, windows, or mac file system;
% (2) The path returned by the code is always a full path, so if the user
% changes directory to somewhere other than HOMEDIR (or if there is no
% HOMEDIR because you're not doing functional analysis), you still get the
% right answer.

% the 2nd and 3rd output arguments are no longer relevant...
if nargout > 1
	warning('The second and third output arguments are deprecated.')
	anatDir = '';
	subject = '';  
end


% (1) check if it's saved
mrGlobals
mrSessPath = fullfile(HOMEDIR, 'mrSESSION.mat');
if exist(mrSessPath, 'file')
	load(mrSessPath);
	if exist('vANATOMYPATH', 'var') && exist(vANATOMYPATH, 'file')
		% one last check: is the path a relative or absolute path?
		% if it's relative, we should assume it's relative to HOMEDIR, so
		% if the user changed to a different dir, it doesn't get confused.
		if ~isequal(vANATOMYPATH, fullpath(vANATOMYPATH))
			pth = fullfile(HOMEDIR, vANATOMYPATH);
		else
			pth = vANATOMYPATH;
		end
		return
	end
end

% (2) no path found? Guess a single default possibility.
fileFormat = prefsFormatCheck;
if isequal( lower(fileFormat), 'nifti' )
	defaultFileName = 't1.nii.gz';
else
	defaultFileName = 'vAnatomy.dat';
end
pth = fullfile(getAnatomyPath, defaultFileName);

% now set it. (If the default doesn't exist, this code will prompt the user
% to set it manually.)
pth = setVAnatomyPath(pth);

return
