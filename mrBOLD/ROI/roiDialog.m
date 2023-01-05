function [rois ok] = roiDialog(roiFolder, dirList, callbackFlag)
% Dialog to select one or more ROI files.
%
%    [rois ok] = roiDialog([roiFolder], [dirList], callbackFlag)
%
% This function produces a GUI designed to help sift through the clutter of
% many ROIs being shared across users. It should make it easier for users
% to organize ROI, allowing them to flip between different folders
% containing ROI files, and to create subfolders for different subtypes of
% ROIs. (For instances, if different projects have different criteria for
% how to choose an ROI, the ROIs can be kept in separate subfolders for
% each project -- allowing users to share the anatomies and segmentations
% but keep ROIs separate).
%
%
% ras, 07/2009.
if notDefined('callbackFlag'),	callbackFlag = 0;			end
if notDefined('roiFolder'),		roiFolder = '';				end
if notDefined('dirList'),
	% use standard mrVista directories
	dirList = {'Inplane/ROIs/' '3DAnatomy/ROIs' 'Gray/ROIs' 'Volume/ROIs'};
end

if callbackFlag==1
	% the dialog controls will pass specialized values for the 'roiFolder'
	% argument as callbacks. 
	switch lower(roiFolder)
		case 'selectrois',		roiDialog_selectROIs;  
		case 'deselectrois',	roiDialog_deselectROIs;
		case 'selectdir',		roiDialog_selectDir;   
		case 'setroiinfo',		roiDialog_setROIInfo;
		case 'setfilter',		setRoiListText(get(gcf, 'UserData'));
		case 'newfolder',		roiDialog_newFolder;
		case 'copytofolder',	roiDialog_copyToFolder;
		case 'movetofolder',	roiDialog_moveToFolder;
	end
	return
end

% create the dialog figure
h = roiDialog_openFig(roiFolder, dirList);

% wait for a user response
uiwait;

% parse the user response
data = get(h, 'UserData');
delete(h);
if data.ok==0
	% user pressed cancel or closed the dialog; 
	% return an empty ROI list
	rois = {};
	ok = 0;
else
	rois = {};
	for ii = 1:length(data.rois)
		rois{ii} = fullfile(data.roiFolder, [data.rois{ii} '.mat']);
	end
	ok = 1;
end

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function h = roiDialog_openFig(roiFolder, dirList)
% create the dialog figure.
if isempty(get(0, 'CurrentFigure'))
	parent = 0;
else
	parent = gcf;
end
h = figure('Units', 'pixels', 'Position', [100 400 750 450], ...
		   'NumberTitle', 'off', 'Name', 'ROI Select Dialog', ...
		   'MenuBar', 'none', ...
		   'Color', [.9 .9 .9], 'CloseRequestFcn', 'uiresume;');
centerfig(h, parent);
figOffscreenCheck(h);

%% create an initial data structure for the figure
%  this lists all the starting ROI folders, w/o subdirectories.
data.initDirList = dirList; 

% this list will be populated with subdirectories of the initial directory
% list. The plan is to check directories one level deep (not recursive; no
% subfolders-of-subfolders). So for instance, within 3DAnatomy/ROIs, you
% could have different folders for different users: 3DAnatomy/ROIs/rory/,
% or 3DAnatomy/ROIs/barack. (Or by project, criteria, etc.)
% let's populate this list now.
data.dirList = roiFolderList(data);

% this field will have the selected ROIs
data.rois = {};

% this field will have the the folder containing the selected ROIs.
data.roiFolder = '';

% flag indicating whether the user pressed the 'OK' button
data.ok = 0;

%% create a popup for selecting the current ROI directory.

% find the appropirate initial dir to display. this is the string
% roiFolder. so we look through the cell array data.dirList (all possible
% directories) to find the desired initial string (roiFolder), and we use
% this index (called 'val') as the initial value for the field
% data.ui.folder.
val = strmatch(roiFolder, data.dirList);
if length(val) > 1,
    val = strmatch(roiFolder, data.dirList, 'exact');
end
if isempty(val), val = 1; end
data.ui.folder = uicontrol('Units', 'norm', 'Position', [.3 .9 .55 .06], ...
						   'Style', 'popup', 'String', data.dirList, ...
						   'BackgroundColor', 'w', 'FontSize', 10, ...
						   'Callback', 'roiDialog(''SelectDir'', [], 1); ',...
                           'Value', val);
					   
% label for popup
uicontrol('Units', 'norm', 'Position', [.3 .96 .55 .04], ...
		  'Style', 'text', 'String', 'ROI Folder:', ...
		  'BackgroundColor', [.9 .9 .9], 'FontSize', 10, ...
		  'HorizontalAlignment', 'left', ...
		  'FontWeight', 'bold');

%% create an edit field to set filter the ROI names list.
data.ui.filter = uicontrol('Units', 'norm', 'Position', [.3 .8 .55 .06], ...
						   'Style', 'edit', 'String', '', ...
						   'BackgroundColor', 'w', 'FontSize', 10, ...
						   'Callback', 'roiDialog(''SetFilter'', [], 1); ');

% label for edit field
uicontrol('Units', 'norm', 'Position', [.3 .86 .55 .04], ...
		  'Style', 'text', 'String', 'Find ROIs matching pattern:', ...
		  'HorizontalAlignment', 'left', ...
		  'BackgroundColor', [.9 .9 .9], 'FontSize', 10, ...
		  'FontWeight', 'bold');


%% create the main ROI files listbox.
% the callback will update the info fields for the last ROI selected in the
% listbox. 
data.ui.roiList = uicontrol('Units', 'norm', 'Position', [.3 .1 .55 .68], ...
						   'Style', 'listbox', 'String', '', ...
						   'BackgroundColor', 'w', 'FontSize', 9, ...
						   'Min', 1, 'Max', 3, 'Value', [], ...
						   'Callback', 'roiDialog(''SetROIInfo'', [], 1); ');

%% create a set of buttons to select/deselect ROIs, and do other things
%% like make a new directory.
% select current ROIs
uicontrol('Units', 'norm', 'Position', [.85 .66 .15 .05], ...
	  	  'Style', 'pushbutton', 'String', 'Select', ...
		  'BackgroundColor', [.86 .9 .86], 'FontSize', 10, ...
		  'Callback', 'roiDialog(''SelectROIs'', [], 1); ');
	  
% deselect current ROIs
uicontrol('Units', 'norm', 'Position', [.85 .6 .15 .05], ...
	  	  'Style', 'pushbutton', 'String', 'Deselect', ...
		  'BackgroundColor', [.9 .86 .9], 'FontSize', 10, ...
		  'Callback', 'roiDialog(''DeselectROIs'', [], 1); ');

% create new ROI directory
uicontrol('Units', 'norm', 'Position', [.85 .95 .15 .05], ...
	  	  'Style', 'pushbutton', 'String', 'Make New Folder', ...
		  'BackgroundColor', [.86 .86 .86], 'FontSize', 10, ...
		  'Callback', 'roiDialog(''NewFolder'', [], 1); ');
	 
% copy current ROIs to a different folder
uicontrol('Units', 'norm', 'Position', [.85 .54 .15 .05], ...
	  	  'Style', 'pushbutton', 'String', 'Copy ROIs to Folder', ...
		  'BackgroundColor', [.86 .86 .86], 'FontSize', 10, ...
		  'Callback', 'roiDialog(''CopyToFolder'', [], 1); ');
	  
% move current ROIs to a different folder
uicontrol('Units', 'norm', 'Position', [.85 .48 .15 .05], ...
	  	  'Style', 'pushbutton', 'String', 'Move ROIs to Folder', ...
		  'BackgroundColor', [.86 .86 .86], 'FontSize', 10, ...
		  'Callback', 'roiDialog(''MoveToFolder'', [], 1); ');
	  
% checkbox to auto-select the current highlighted ROIs in the listbox
data.ui.autoSelect = uicontrol('Units', 'norm', 'Position', [.85 .42 .15 .04], ...
				   'Style', 'checkbox', 'String', 'Autoselect Highlighted ROIs', ...
				   'Value', 1, ...
				   'BackgroundColor', [.9 .9 .9], 'FontSize', 9);

% checkbox to auto-load ROI metadata while browsing
% (turning this off can speed up the dialog)
data.ui.autoLoadMetadata = uicontrol('Units', 'norm', 'Position', [.85 .36 .15 .04], ...
				   'Style', 'checkbox', 'String', 'Show ROI Metadata', ...
				   'Value', 1, ...
				   'BackgroundColor', [.9 .9 .9], 'FontSize', 9);


%% create info fields which will describe the most recently-selected ROI.
% ROI file label
uicontrol('Units', 'norm', 'Position', [.01 .72 .2 .05], ...
		   'Style', 'text', 'String', 'ROI File:', ...
		   'HorizontalAlignment', 'left', ...
		   'BackgroundColor', [.9 .9 .9], 'FontSize', 9, 'FontWeight', 'bold');

% ROI file
data.ui.fileInfo = uicontrol('Units', 'norm', 'Position', [.01 .64 .2 .08], ...
						   'Style', 'text', 'String', '', ...
						   'HorizontalAlignment', 'left', ...
						   'BackgroundColor', [.9 .9 .9], 'FontSize', 8);

% date created label
uicontrol('Units', 'norm', 'Position', [.01 .59 .2 .05], ...
		   'Style', 'text', 'String', 'Created:', ...
		   'HorizontalAlignment', 'left', ...
		   'BackgroundColor', [.9 .9 .9], 'FontSize', 9, 'FontWeight', 'bold');
					   
% date created
data.ui.fileCreated = uicontrol('Units', 'norm', 'Position', [.01 .53 .2 .06], ...
						   'Style', 'text', 'String', '', ...
						   'HorizontalAlignment', 'left', ...						   
						   'BackgroundColor', [.9 .9 .9], 'FontSize', 8);

% date last modified label
uicontrol('Units', 'norm', 'Position', [.01 .48 .2 .05], ...
		   'Style', 'text', 'String', 'Modified:', ...
		   'HorizontalAlignment', 'left', ...
		   'BackgroundColor', [.9 .9 .9], 'FontSize', 9, 'FontWeight', 'bold');


% date last modified
data.ui.fileModified = uicontrol('Units', 'norm', 'Position', [.01 .42 .2 .06], ...
						   'Style', 'text', 'String', '', ...
						   'HorizontalAlignment', 'left', ...						   
						   'BackgroundColor', [.9 .9 .9], 'FontSize', 8);
% comments label
uicontrol('Units', 'norm', 'Position', [.01 .37 .2 .05], ...
		   'Style', 'text', 'String', 'Comments:', ...
		   'HorizontalAlignment', 'left', ...
		   'BackgroundColor', [.9 .9 .9], 'FontSize', 9, 'FontWeight', 'bold');

% comments
data.ui.fileComments = uicontrol('Units', 'norm', 'Position', [.01 .05 .2 .32], ...
						   'Style', 'text', 'String', '', 'Min', 0, 'Max', 7, ...
						   'HorizontalAlignment', 'left', ...						   
						   'BackgroundColor', [.9 .9 .9], 'FontSize', 8);


%% create 'OK' and 'Cancel' buttons.
cb = ['TMP = get(gcf, ''UserData''); ' ...
	  'TMP.ok = 1; ' ...
	  'set(gcf, ''UserData'', TMP); ' ...
	  'clear TMP; uiresume; '];
data.ui.ok = uicontrol('Units', 'norm', 'Position', [.2 .02 .2 .06], ...
					   'Style', 'pushbutton', 'String', 'Load ROIs', ...
					   'ForegroundColor', [1 1 1], ...
					   'BackgroundColor', [0 .5 0], 'FontSize', 12, ...
					   'Callback', cb);

data.ui.cancel = uicontrol('Units', 'norm', 'Position', [.6 .02 .2 .06], ...
					   'Style', 'pushbutton', 'String', 'Cancel', ...
					   'ForegroundColor', [1 1 1], ...
					   'BackgroundColor', [.5 0 0], 'FontSize', 12, ...
					   'Callback', 'uiresume; ');

%% set the figure's UserData with the dialog data.
set(h, 'UserData', data);				 
				   
%% initialize the settings of the controls.
% set the initial ROI folder
roiDialog_selectDir;

% populate the ROI files list with the ROI files found in this folder
setRoiListText(data);
		

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function dirList = roiFolderList(data)
% this function returns the set of folders which may contain ROI files.
% This includes the initial set of ROI folders, as well as subfolders in
% the initial folder list. The plan is to check directories one level deep 
% (not recursive; no subfolders-of-subfolders). 
% 
% So for instance, within 3DAnatomy/ROIs, you
% could have different folders for different users: 3DAnatomy/ROIs/rory/,
% or 3DAnatomy/ROIs/barack. (Or by project, criteria, etc.)
dirList = {};
for ii = 1:length(data.initDirList)
	% first, the parent dir.
	% (the fullfile call makes the file separators conform to the current
	% operating system -- I'm looking at you, Windows):
	[p f] = fileparts(data.initDirList{ii});
	dirList{end+1} = fullfile(p, f);
	
	% now, the subdirectories for this parent dir.
	w = dir(data.initDirList{ii});
	w = w(3:end);  % remove . and .. entries
	w = w([w.isdir]);
	for jj = 1:length(w)
		dirList{end+1} = fullfile(data.initDirList{ii}, w(jj).name);
	end
end

% add an option to browse for an external ROI directory.
dirList{end+1} = 'Browse...';

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function roiFiles = roiFileList(data)
% this function returns a list of all ROI files found in the selected ROI
% folder. If the user has typed a file pattern into the filter field, it also 
% filters the ROI list to match that file pattern.
roiFolders = roiFolderList(data);
folder = roiFolders{ get(data.ui.folder, 'Value') };
filter = strtok( get(data.ui.filter, 'String') );

if isempty(filter)
	% we just look for .mat files in the folder
	pattern = [folder filesep '*.mat'];
else
	% we add the filter; we also add '*' to either side, so the user
	% doesn't have to always type the asterisks
	pattern = [folder filesep '*' filter '*.mat'];
end

roiFiles = {};

w = dir(pattern);
for ii = 1:length(w)
	[p roiFiles{ii}] = fileparts( w(ii).name ); 
end

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function setRoiListText(data)
% this function sets the text in the main ROI list, indicating which ROIs
% are higlighted and which aren't.
roiFiles = roiFileList(data);
str = roiFiles;

if isempty(roiFiles)
	roiFiles = {'(No files found.)'};
end

for ii = 1:length(roiFiles)
	if ismember(roiFiles{ii}, data.rois)
		str{ii} = ['*** ' roiFiles{ii} ' ***'];
	else
		str{ii} = ['   ' roiFiles{ii} '   '];
	end
end

% also do an out-of-bounds check on the highlighted ROIs
val = get(data.ui.roiList, 'Value');
val = val( val < length(str) );

set(data.ui.roiList, 'String', str, 'Value', val);

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function roiDialog_selectROIs
% this marks a set of highlighted ROIs in the listbox as 'selected' ROIs. 
%
% a note about this: I'm trying to find a compromise between the
% multi-select ability of listboxes and the ease-of-use of checkboxes. I
% want the user to be able to look at the metadata for ROIs before deciding
% to select the ROI as one to load or not. So, instead of having the user
% highlight all the ROIs he/she wants, and using Shift-click or
% Control-click to select multiple options, I have him/her highlight ROIs,
% then press the 'Select' or 'Deselect' buttons. The selected ROIs are
% marked with asterisks in the ROI list. 
data = get(gcf, 'UserData');

highlightedRois = get(data.ui.roiList, 'Value');

roiFiles = roiFileList(data);

% add to the list of selected ROIs in the data struct.
data.rois = [data.rois roiFiles(highlightedRois)];

set(gcf, 'UserData', data);

% mark as selected in the listbox text
setRoiListText(data);

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function roiDialog_deselectROIs
% this marks a set of highlighted ROIs in the listbox as non-selected ROIs. 
%
% a note about this: I'm trying to find a compromise between the
% multi-select ability of listboxes and the ease-of-use of checkboxes. I
% want the user to be able to look at the metadata for ROIs before deciding
% to select the ROI as one to load or not. So, instead of having the user
% highlight all the ROIs he/she wants, and using Shift-click or
% Control-click to select multiple options, I have him/her highlight ROIs,
% then press the 'Select' or 'Deselect' buttons. The selected ROIs are
% marked with asterisks in the ROI list. 
data = get(gcf, 'UserData');

highlightedRois = get(data.ui.roiList, 'Value');

roiFiles = roiFileList(data);

% remove from the list of selected ROIs in the data struct.
for ii = highlightedRois
	data.rois = setdiff( data.rois, roiFiles{ii} );
end

set(gcf, 'UserData', data);

% mark as selected in the listbox text
setRoiListText(data);

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function roiDialog_selectDir
% set the current ROI folder.
data = get(gcf, 'UserData');

str = get(data.ui.folder, 'String');
folderIndex = get(data.ui.folder, 'Value');

% if the user selected to browse for a new folder, let the user select that
% folder now, and add it to the list of ROI folders
if strncmpi( str{folderIndex}, 'browse', 6 )
	txt = 'Select an ROI directory to browse';
	browseDir = uigetdir(pwd, txt);
	data.initDirList = [{browseDir} data.initDirList];
	folderIndex = 1;
end

% update the list of ROIs to include any new subfolders.
data.dirList = roiFolderList(data);

% mark the selected ROI folder.
data.roiFolder = fullpath( data.dirList{folderIndex} );

set(data.ui.folder, 'Value', folderIndex, 'String', data.dirList);

% currently, the dialog allows the user to only load ROIs from one folder
% at a time (may change later). Re-initialize the selected ROIs since 
% we changed the folder.
data.rois = {};

% update the ROI list with the files in this directory.
setRoiListText(data);

set(gcf, 'UserData', data);

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function roiDialog_setROIInfo
% this is a callback from the ROI files list. It populates the ROI info 
% fields with the most-recently highlighted ROI in the list. If the user
% has selected the option to auto-select, it will also select only those
% items that are currently highlighted.
data = get(gcf, 'UserData');
roiFiles = roiFileList(data);
sel = get(data.ui.roiList, 'Value');

if isempty(roiFiles)
	return
end

I = sel(end); % index of last highlighted ROI
mostRecentRoi = strtok( roiFiles{I} );
mostRecentRoi = fullfile(data.roiFolder, [mostRecentRoi '.mat']);

% update info fields, only if the user requests it
updateInfoFields = get(data.ui.autoLoadMetadata, 'Value');
if updateInfoFields==1
	if exist(mostRecentRoi, 'file')
		% load it and update the ROI fields
		try
			load(mostRecentRoi, 'ROI');
			set(data.ui.fileInfo, 'String', fullfile(data.roiFolder, ROI.name));
			set(data.ui.fileCreated, 'String', ROI.created);
			set(data.ui.fileModified, 'String', ROI.modified);
			set(data.ui.fileComments, 'String', ROI.comments);
        catch ME
			disp(ME.message);
            % warn the user it doesn't appear to be an ROI file.
			fprintf('ROI File %s doesn''t appear to be an ROI file.\n', mostRecentRoi);
		end
	else
		% warn the user it couldn't be found.
		fprintf('ROI File %s couldn''t be loaded.\n', mostRecentRoi);
	end
end

autoSelect = get(data.ui.autoSelect, 'Value');
if autoSelect==1
	data.rois = {};
	set(gcf, 'UserData', data);
	roiDialog_selectROIs;
end
	

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function roiDialog_newFolder
% let the user create a new subfolder in the current folder.
% There is some potential for confusion here: we can let the user create a
% subfolder within a subfolder (e.g., Inplane/ROIs/rory/temp), but to keep
% things simple the dialog only looks one level deep. In this case, you
% could create the new folder, but not access it unless you choose the
% 'Browse' option. I'm okay with this for now.
data = get(gcf, 'UserData');

folderName = inputdlg({'Enter name of new ROI folder:'}, ...
				       ['Making ROI subfolder within ' data.roiFolder], ...
					   1, {''}, 'on');

folderName = folderName{1};

if isempty(folderName)
	if prefsVerboseCheck > 1
		fprintf('[%s]: Aborted making new ROI folder.\n', mfilename);
	end
	return
end

newFolder = fullfile(data.roiFolder, folderName);
mkdir(newFolder);

if prefsVerboseCheck >= 1
	fprintf('[%s]: Made new folder %s.\n', mfilename, newFolder);
end

data.initDirList = [data.initDirList newFolder];
data.dirList = roiFolderList(data);
set(gcf, 'UserData', data);

val = cellfind(data.dirList, newFolder);
set(data.ui.folder, 'Value', val, 'String', data.dirList);

roiDialog_selectDir;

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function roiDialog_copyToFolder
% copy the higlighted ROIs to a subfolder of the user's choosing.
data = get(gcf, 'UserData');

highlightedRois = get(data.ui.roiList, 'Value');
roiFiles = roiFileList(data);

% put up a dialog to get the target folder
dlg.fieldName = 'targetFolder';
dlg.style = 'listbox';
dlg.string = 'Copy highlighted ROIs to which folder?';
dlg.list = roiFolderList(data);
dlg.value = get(data.ui.folder, 'Value');

[resp ok] = generalDialog(dlg, 'Copy ROIs to folder');
if ~ok, return; end

% copy the ROIs to the target folder
for ii = highlightedRois(:)'
	srcPath = fullfile(data.roiFolder, [roiFiles{ii} '.mat']);
	targetPath = fullfile(resp.targetFolder{1}, roiFiles{ii});
	
	[success msg msgId] = copyfile(srcPath, resp.targetFolder{1});
	
	if prefsVerboseCheck >= 1
		if success==1
			fprintf('[%s]: copied file %s to %s.\n', mfilename, ...
						srcPath, targetPath);
		else
			fprintf('[%s]: could not copy file %s to %s.\n', mfilename, ...
						srcPath, targetPath);
					
			fprintf('Message ID %i: %s.\n', msgId, msg);					
		end
	end
end

return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function roiDialog_moveToFolder
% move the higlighted ROIs to a subfolder of the user's choosing.
data = get(gcf, 'UserData');

highlightedRois = get(data.ui.roiList, 'Value');
roiFiles = roiFileList(data);

% put up a dialog to get the target folder
dlg.fieldName = 'targetFolder';
dlg.style = 'listbox';
dlg.string = 'Move highlighted ROIs to which folder?';
dlg.list = roiFolderList(data);
dlg.value = get(data.ui.folder, 'Value');

[resp ok] = generalDialog(dlg, 'Move ROIs to folder');
if ~ok, return; end

% copy the ROIs to the target folder
for ii = highlightedRois(:)'
	srcPath = fullfile(data.roiFolder, [roiFiles{ii} '.mat']);
	targetPath = fullfile(resp.targetFolder{1}, roiFiles{ii});
	
	[success msg msgId] = movefile(srcPath, resp.targetFolder{1});
	
	if prefsVerboseCheck >= 1
		if success==1
			fprintf('[%s]: moved file %s to %s.\n', mfilename, ...
						srcPath, targetPath);
		else
			fprintf('[%s]: could not move file %s to %s.\n', mfilename, ...
						srcPath, targetPath);
					
			fprintf('Message ID %i: %s.\n', msgId, msg);					
		end
	end
end

% update the ROI file list for this directory
roiDialog_selectDir;

return


