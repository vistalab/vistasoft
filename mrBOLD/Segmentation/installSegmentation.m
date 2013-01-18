function installSegmentation(query, keepAllNodes, filePaths, numGrayLayers)
%
% function installSegmentation(query, keepAllNodes, filePaths, numGrayLayers)
%
% Rebuild coords after a new segmentation.
%
% Note: could automatically rebuild Gray/corAnals by xforming from inplane, but we
% would have to do this for each dataType.
%
% 12/8/00 Wandell and Huk
% djh, 2/14/2001
%    Uses hiddenGray and hiddenFlat structures rather than opening windows.
%    Uses fullfile rather than cd'ing into the directory
% ras, dy, al 01/09: added option to keep all nodes from each hemisphere.
% ras 06/09: eliminated a redundant set of file requests. Streamlined the
% logic, so it doesn't call a large series of nested files. Condensed file
% selection to a single dialog, which guesses reasonable defaults.
if ~exist('query','var')
	% query only if Gray, Volume, or Flat files are found
	global HOMEDIR %#ok<TLEV>
	w1 = dir( fullfile(HOMEDIR, 'Volume*') );
	w2 = dir( fullfile(HOMEDIR, 'Gray*') );
	w3 = dir( fullfile(HOMEDIR, 'Flat*') );
	if (~isempty(w1) || ~isempty(w2) || ~isempty(w3))
		query = 1;
	else
		query = 0;
	end
end

% if keepAllNodes is true, we store coordinates for all gray voxels. If it
% is false, then we only store gray voxels within the functional field of
% view. The latter is more resource efficient. The former has greater
% flexibility, for example to visualize ROIs on a mesh that extend beyond
% the field of view from a particular session.
if ~exist('keepAllNodes','var'), keepAllNodes=0; end

if notDefined('filePaths')
	% get a set of file paths in a dialog
	filePaths = segmentationFilesDialog;
    if isempty(filePaths), return; end
end

if ~exist('numGrayLayers', 'var')
    resp = inputdlg('number of gray layers?', 'enter a number', 1, {'3'});
    numGrayLayers = str2double(resp);
end
    
if query
    resp = questdlg('Delete Gray and all Flat data files and close all Gray and Flat windows?');
else
    resp = 'Yes';
end

% delete coords and rebuild
if ~strcmp(resp,'Yes')
	disp('Coords, corAnal, and parameter map files not deleted.');
    return;
end
closeAllGrayWindows;
closeAllFlatWindows;

% Deletes coords, corAnal, and other parameter map files
cleanGray;
cleanAllFlats;

% ras 06/09: initially the logic was different here. The function would
% call 'initHiddenGray', which in turn would call 'switch2Gray', which
% would call 'getGrayCoords', which would detect that you wanted to
% rebuild, then call 'buildGrayCoords'. This was a little confusing, but
% moreover didn't work if you wanted to keep all nodes (most of the
% intermediate functions don't allow such a parameter, and it wouldn't make
% much sense most of the time). So, I make it more direct here.

% build the gray coordinates fields (this saves the coords.mat file)
if keepAllNodes==1
	% the gray nodes/edges are either loaded or built in the call to
	% initHiddenGray above. It is awkward to pass a flag to this
	% function to load all nodes, so we recompute the nodes/edges here.
	if prefsVerboseCheck >= 1
		fprintf('[%s]: Rebuilding Gray coordinates with ALL nodes. \n', ...
				mfilename);
	end
	buildGrayCoords([], [], 1, filePaths, numGrayLayers);
else
	if prefsVerboseCheck >= 1
		fprintf(['[%s]: Rebuilding Gray coordinates with nodes only ' ...
				 'where the inplanes have data. \n'], mfilename);
	end
	buildGrayCoords([], [], 0, filePaths, numGrayLayers);
end

disp('Rebuilt Gray coords. Deleted old corAnal and parameter map files.');

return;
% /-----------------------------------------------------------/ %




% /-----------------------------------------------------------/ %
function filePaths = segmentationFilesDialog
% dialog to get the file paths for installing a segmentation.

%% first, guess default paths
defaultLeftClass = '';
defaultRightClass = '';
defaultLeftGray = '';
defaultRightGray = '';

try
	% this depends on whether we generally save things in NIFTI format, or
	% default (mrGray) format
	format = prefsFormatCheck;

    % This line seems to be unused so let's get rid of it...
    % 	% also want the anat path
    % 	anatPath = getAnatomyPath;

	% left class file
	if isequal( lower(format), 'nifti' )
		pattern = fullfile(pwd, '3DAnatomy', 'Left', '*.nii.gz');		
	else
		pattern = fullfile(pwd, '3DAnatomy', 'Left', '*.?lass');
	end
	w = dir(pattern);
	if ~isempty(w),  
		defaultLeftClass = fullfile(pwd, '3DAnatomy', 'Left', w(1).name);
	end
	
	% right class file
	if isequal( lower(format), 'nifti' )
		pattern = fullfile(pwd, '3DAnatomy', 'Right', '*.nii.gz');		
	else
		pattern = fullfile(pwd, '3DAnatomy', 'Right', '*.?lass');
	end
	w = dir(pattern);
	if ~isempty(w),  
		defaultRightClass = fullfile(pwd, '3DAnatomy', 'Right', w(1).name);
	end
	
	% left gray file
	if isequal( lower(format), 'nifti' )
		% we don't need to assign a value here
	else
		pattern = fullfile(pwd, '3DAnatomy', 'Left', '*.?ray');
		w = dir(pattern);
		if ~isempty(w),
			defaultLeftGray = fullfile(pwd, '3DAnatomy', 'Left', w(1).name);
		end
	end
	
	% right gray file
	if isequal( lower(format), 'nifti' )
		% we don't need to assign a value here
	else
		pattern = fullfile(pwd, '3DAnatomy', 'Right', '*.?ray');
		w = dir(pattern);
		if ~isempty(w),
			defaultRightGray = fullfile(pwd, '3DAnatomy', 'Right', w(1).name);
		end
	end
	
catch ME
    warning(ME.identifier, ME.mesage);
	% can't get it? don't worry...
	
end

%% now build the dialog structure
dlg(1).fieldName	= 'leftClassFile';
dlg(end).style		= 'filename';
dlg(end).string		= 'Left Classification File (.class, NIFTI)?';
dlg(end).value		= defaultLeftClass;

dlg(end+1).fieldName	= 'rightClassFile';
dlg(end).style		= 'filename';
dlg(end).string		= 'Right Classification File (.class, NIFTI)?';
dlg(end).value		= defaultRightClass;

dlg(end+1).fieldName	= 'leftPath';
dlg(end).style		= 'filename';
dlg(end).string		= 'Left Gray Graph (.gray)? Leave empty for NIFTI files.';
dlg(end).value		= defaultLeftGray;

dlg(end+1).fieldName	= 'rightPath';
dlg(end).style		= 'filename';
dlg(end).string		= 'Right Gray Graph (.gray)? Leave empty for NIFTI files.';
dlg(end).value		= defaultRightGray;



%% put the dialog to the user
[resp ok] = generalDialog(dlg, 'Install Gray Segmentation');
if ~ok
	filePaths = [];
    fprintf('User aborted.\n'); 
    return; 
end

%% parse the response
filePaths = {resp.leftClassFile resp.rightClassFile ...
			 resp.leftPath resp.rightPath};

return
