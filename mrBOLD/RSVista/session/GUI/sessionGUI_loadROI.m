function GUI = sessionGUI_loadROI(rois, viewer); 
% Load a saved ROI into a mrViewer UI.
%
% GUI = sessionGUI_loadROI(<rois=get from GUI>, <mrViewer handle>); 
%
% rois can be specified as the name of an ROI in the relevant ROI dir
% (inplane or volume, depending on the GUI's roi type), a path to an
% ROI file, an index into the ROI list being displayed, a handle 
% to a uicontrol with the ROI list, or a cell array of several of these
% specifications. By default, it uses the GUI.controls.roi listbox. 
%
% This function will load the ROIs into the current mrViewer UI specified
% by GUI.settings.viewer. An alternate viewer can be specified by passing 
% the handle to the main UI figure. If no viewer is open, this will open
% one.
%
%
% ras, 07/06.
mrGlobals2;

if notDefined('rois'), rois = GUI.controls.roi; end
if notDefined('viewer')
    if isempty(GUI.viewers)
        viewer = sessionGUI_viewInplane;
	else
	    viewer = GUI.viewers(GUI.settings.viewer); 
	end
end

% parse the format of the rois arg, getting it into the format
% of a cell array of file paths
if iscell(rois)
    % check that each entry is a path
    for i = 1:length(rois)
        rois{i} = sessionGUI_roiPath(rois{i});
    end
    
elseif isnumeric(rois) & all(mod(rois, 1)==0)
    % index into ROIs list
    for i = 1:length(rois)
        roiList{i} = sessionGUI_roiPath(rois(i));
    end
    rois = roiList;
    
elseif ishandle(rois)
    % get from uicontrol
    rois = get(rois, 'Value');
    for i = 1:length(rois)
        roiList{i} = sessionGUI_roiPath(rois(i));
    end
    rois = roiList;
    
elseif ischar(rois)
    rois = {sessionGUI_roiPath(rois)};

else
    error('Invalid ROI specification. ')
    
end


% Now that we have a cell array of paths, load each one into the current
% viewer:
ui = get(viewer, 'UserData');
for i = 1:length(rois)
    ui = mrViewLoad(ui, rois{i}, 'roi'); 
end

% select the last one in the list
mrViewROI('select', ui, length(ui.rois));


return

