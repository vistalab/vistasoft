function pth = prefsDefaultAnatPath;
% Return the location where subjects' anatomy files are located in the
% current file system, setting to some default guesses if needed.
%
%  pth = prefsDefaultAnatPath;
%
% BACKGROUND: The recommended way of linking between functional
% and anatomical data sets in mrVista is to create a folder (or
% link/shortcut) named '3DAnatomy' in each functional directory, pointing
% to the anatomy directory. However, there are cases where it's useful to try 
% to guess where the anatomies are kept without relying on this link existing.
%
% The VISTA preference 'defaultAnatomyPath' specifies where you can find
% the top-level directory containing subjects' anatomical sessions, within
% the local filesystem. Within this, it is the convention that each subject
% has there data in an appropriately named subdirectory, e.g., if the
% default path is /myRAID/data/anatomy, and the subject is John Doe:
%	/myRAID/data/anatomy/JohnDoe/
%	which may contain anatomical files:
%	/myRAID/data/anatomy/JohnDoe/t1.nii.gz   
%	/myRAID/data/anatomy/JohnDoe/vAnatomy.dat
%	/myRAID/data/anatomy/JohnDoe/Right/right.class
%
%	...and so on. Use the function 'getAnatomyPath' to find a particular
%	subjects' anatomy directory.
%
% (Again, note that mrVista doesn't force you to keep all your anatomies in this
% folder. It is generally easier just to link to the anatomy, wherever it
% is, using the 3DAnatomy format. But this path can be useful for an
% initial guess as to where the anatomy will be found.)
%
% This function checks if this preference has been already set. If so, it
% returns the current value. If not, it initializes it to some default
% values (depending on the operating system), which have been historically
% used the Stanford VISTA lab. 
%
% Use 'editPreferences' to modify this default to fit your local file
% structure.
% 
% 
% ras, 07/2009.

if ~ispref('VISTA', 'defaultAnatomyPath') 
	if ispc
		defaultPath = 'X:\anatomy';
	else
		defaultPath = '/biac2/wandell/data/anatomy/';
	end
	    setpref('VISTA', 'defaultAnatomyPath', defaultPath);	
    fprintf('[%s]: ', mfilename);
    fprintf('Initializing VISTA preference ''defaultAnatomyPath'' to ');
	fprintf('%s. \nThis will specify where to find ', defaultPath);
    fprintf('3D Anatomy files for each subject, if they''re,');
    fprintf('not kept (or linked to) in the ''3DAnatomy'' directory. \n\n');

	fprintf('Subject anatomies should be stored by subject name, e.g.: ');
    fprintf('%s%sJohnDoe%s. \n\n', defaultPath, filesep, filesep);

	fprintf('To modify this setting, use ''EditPreferences'' or type: \n');
	fprintf('setpref(''VISTA'', ''defaultAnatomyPath'', ''newPath''). \n');
end

pth = getpref('VISTA', 'defaultAnatomyPath');

return