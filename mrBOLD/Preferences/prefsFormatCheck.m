function verbose = prefsFormatCheck
% checks 'VISTA' preference groupfor a file format setting 
%
%   verbose = prefsFormatCheck;
%
% This variable determines how many data files (including t1-weighted
% anatomies, segmentation files, and parameter maps) are saved in mrVista. 
% 
% There are two possible values allowed:
%	'default': This indicates that the pre-existing, specialized formats
%	adopted by mrLoadRet/mrVista will be used:
%		volume anatomies will use the mrGray *.dat format;
%		inplane anatomies will be saved as Inplane/anat.mat in each
%		session;
%		segmentation files will be mrGray *.class / *.gray files;
%		parameter maps will be saved as .mat files.
%
%	'nifti': these formats will all employ NIFTI files. The segmentation
%	files (normally kept in .class files for each hemisphere) should be
%	saved as a labeled NIFTI file from ITKGray; anatomies and parameter
%	maps will be loaded/saved as compressed NIFTI. ***as of 6/2008, this
%	functionality is not fully implemented.*** 
%		* The 'grow_gray' MEX file needs to be tested and stable on all 
%		machines: whereas before mrGray was a Windows-only bottleneck, once
%		the gray matter graph was saved, it could be read from any system.
%		The grow_gray would need to be employed everytime a segmentation is
%		installed, and is currently not stable enough to rely on it;
%		* The inplane anatomy/paramter map code needs to be updated to
%		allow for NIFTI files.
%
% ras, 09/2006.

if ~ispref('VISTA', 'fileFormat') | ~ismember( getpref('VISTA', 'fileFormat'), {'default' 'nifti'} )
    setpref('VISTA', 'fileFormat', 'default');
    fprintf('[%s]: ', mfilename);
    fprintf('Initializing VISTA preference ''fileFormat'' to ''default''. \n');
    fprintf('This will cause files to be saved and loaded in the \n');
	fprintf('legacy, specialized mrVista format: \n');
	fprintf('\tAnatomy files are in mrGray *.dat format;\n');
	fprintf('\tSegmentation files are in mrGray *.class and *.gray formats;\n');
	fprintf('\tInplane anatomies are saved as Inplane/anat.mat;\n');
	fprintf('\tParameter maps are saved as .mat files.\n');
	fprintf('To save these files in NIFTI format, run: \n');
	fprintf('setpref(''VISTA'', ''fileFormat'', ''nifti''). \n');
end
	
verbose = getpref('VISTA', 'fileFormat');

return