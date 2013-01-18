function pth = sessionGUI_roiPath(roi);
% return a full path to an ROI file, given the name of an ROI in the
% current ROI list, or the numeric index. If a full path is already 
% provided, return it unchanged.
mrGlobals2;

% get the parent directory for ROIs
switch get(GUI.controls.roiType, 'Value')
	case 1, parent = roiDir(INPLANE{1},1); % inplane
	case 2, parent = roiDir(VOLUME{1},0); % volume shared
	case 3, parent = roiDir(VOLUME{1},1); % gray local
	case 4, parent = fullfile(HOMEDIR, 'Volume', 'ROIs');  % volume local
	case 5,  % browse for directory
		parent = get(GUI.controls.roiType, 'String');
		parent = parent{end};
end


% use the roi value and the parent directory to construct a full ROI path.
if ischar(roi) & exist(roi, 'file') 
    pth = fullpath(roi); 
    
elseif isnumeric(roi) 
    roiNames = get(GUI.controls.roi, 'String');
    pth = fullfile(parent, roiNames{roi(1)});
    
elseif ischar(roi)
    pth = fullfile(parent, roi);
    
else
    error('Invalid ROI specification. ')
    
end

return