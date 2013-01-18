function GUI = sessionGUI_plotTimeCourse(rois, scans, viewer);
%
%  GUI = sessionGUI_plotTimeCourse(<rois>, <scans=scan group>, <viewer>);
%
% Open a Time Course UI for the selected ROIs. 
% 
% If a viewer is open, will open a time course UI for the currently-selected ROI
% in the selected viewer. If no viewers are open, will open it for the
% selected ROI in the ROI listbox in the session GUI. These are both
% over-ridden if an roi list and/or viewer are manually specified. 
%
%
%
% ras, 07/06.
mrGlobals2;

if notDefined('viewer')
    if isempty(GUI.settings.viewer) | GUI.settings.viewer==0
        viewer = 0;
    else
         viewer = GUI.viewers(GUI.settings.viewer);
    end
end
        
if notDefined('rois')
    if viewer==0 % no viewer, get from saved list
        rois = guiGet('selectedRois');
    else
        rois = {mrViewGet(viewer, 'selectedRoi')};
    end
end

if ~checkfields(GUI, 'controls', 'tcui')
    GUI.controls.tcui = [];
end

% check if an event-related scan group is assigned. 
% If so, use that; otherwise use the GUI selected scans.
if notDefined('scans')
    scans = GUI.settings.scan;
    dt = GUI.settings.dataType;
    if isfield(dataTYPES(dt).scanParams(scans(1)), 'scanGroup') & ...
            ~isempty(dataTYPES(dt).scanParams(scans(1)).scanGroup)
        [scans dt] = er_getScanGroup(INPLANE{1});
    end
end

if notDefined('dt'), dt = guiGet('DataType'); end

% special case: for GLMs data type, the time series will be
% in a different d.t. We don't need to ask the user to confirm 
% in this case, it should be understood.
if isequal(dataTYPES(dt).name, 'GLMs')
	queryFlag = 1;
else
	queryFlag = 0;
end

for i = 1:length(rois)
    tc = timeCourseUI(INPLANE{1}, rois{i}, scans, dt, queryFlag);
    GUI.controls.tcui(end+1) = tc.ui.fig;
end
       

return
