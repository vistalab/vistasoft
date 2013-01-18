function GUI = sessionGUI_selectROIType(type);
% Select the type of ROI to browse using the mrVista Session GUI.
%
% GUI = sessionGUI_selectROIType(<type name, or uicontrol handle>, <GUI>);
%
% Can provide the name or flag of an ROI type (described below), or else a 
% handle to a uicontrol used to  select the ROI type. 
%
% ROI types include:
%	'inplane', 1:	load an ROI from the local Inplane/ROIs directory.
%
%	'volume', 'volume shared', 'gray shared', 2: load an ROI from the 
%	shared volume/gray directory. Usually this is 3DAnatomy/ROIs.
%
%	'gray local', 3: load an ROI from the local Gray/ROIs directory.
%
%	'volume local', 4: load an ROI from the local Volume/ROIs directory.
%
%	'browse', 'browse...', 5: browse for an ROI file. The ROI will be
%	assumed to be in the volume (I|P|R) coordinate system, and will be
%	aligned to the current data based on the saved transform into this
%	space.
%
%  All specifications are case-insensitive.
%
% If the handle to a uicontrol (popup) is provided, will select the
% session based on the currently-selected value of the uicontrol.
%
% If no argument is provided, will get from the GUI.controls.roiType
% listbox.
%
% The GUI input/output args do not generally need to be called, as this
% function will update the global variable GUI, as well as the mrGlobals
% variables. However, it will formally allow keeping this information in 
% other, independent, structures.
%
% ras, 07/03/06.
mrGlobals2;

if notDefined('type'), type = GUI.controls.roiType; end

types = {'inplane' 'volume' 'gray local' 'volume local' 'browse...'};

% parse how the argument was passed
if ischar(type)
    type = cellfind(types, lower(type));
    if isempty(type)
        error('Invalid string value for ''type'' argument.')
    end

elseif isnumeric(type) & mod(type, 1)==0
    % ok as long as it's in [1-5]
    if (type < 1) | (type > 5)
        error('Invalid numeric value for type argument.')
    end
    
elseif ishandle(type)
    type = get(type, 'Value');        
    
end

% update the ROI listbox to have a list of relevant ROIs for this type;
% select the first one by default:
switch type
	case {'inplane' 1}
		w = what( roiDir(INPLANE{1}) );
		
	case {'volume' 'volume shared' 'gray shared' 2}
		w = what( roiDir(VOLUME{1}, 0) );
		
	case {'gray local' 3}
		w = what( roiDir(VOLUME{1}, 1) );
		
	case {'volume local' 4}
		w = what( fullfile(HOMEDIR, 'Volume', 'ROIs') );
		
	case {'browse' 'browse...' 5}
		% for browsing, we ask the user to select the directory to browse
		% (but only if one hasn't already been selected)
		browseDir = get(GUI.controls.roiType, 'String');
		browseDir = browseDir{end};
		if strncmp( lower(browseDir), 'browse', 5 )
			txt = 'Select an ROI directory to browse';
			browseDir = uigetdir( fileparts(HOMEDIR), txt );
		end
		w = what(browseDir);
			
	otherwise
		error('Invalid ROI type.')
end

% if the user selected the 'browse' option, set the popup to reflect the
% browsing directory. Otherwise, reset the text to 'Browse...'.
str = get(GUI.controls.roiType, 'String');
if strncmp(type, 'browse', 5) | type==5
	str{end} = browseDir;
else
	str{end} = 'Browse...';
end
set(GUI.controls.roiType, 'String', str);

rois = {};
for i = 1:length(w.mat), [p rois{i} ext] = fileparts(w.mat{i}); end
rois = sort(rois);

set(GUI.controls.roi, 'String', rois, 'Value', 1);

% keep values in settings
GUI.settings.roiType = type;


return
