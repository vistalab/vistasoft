function GUI = sessionGUI_plotVoxelData(rois, scans, viewer);
%
%  GUI = sessionGUI_plotVoxelData(<rois>, <scans=scan group>, <viewer>);
%
% Open a Multi Voxel UI(s) for the selected ROIs. 
% 
% If a viewer is open, will open an MVUI for the currently-selected ROI
% in the selected viewer. If no viewers are open, will open it for the
% selected ROI in the ROI listbox in the session GUI. These are both
% over-ridden if an roi list and/or viewer are manually specified. 
%
%
%
% ras, 07/06.
mrGlobals2;

if notDefined('viewer')
    if ~isempty(GUI.viewers)
        viewer = GUI.viewers(GUI.settings.viewer);
    else
        viewer = 0; 
    end
end
        
if notDefined('rois')
    if viewer==0 % no viewer, get from saved list
        rois = guiGet('selectedRois');
    else
        rois = {mrViewGet(viewer, 'selectedRoi')};
    end
end

if ~checkfields(GUI, 'controls', 'mvui')
    GUI.controls.mvui = [];
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

if notDefined('dt')
	dt = guiGet('dataType');
end

for i = 1:length(rois)
    mv = multiVoxelUI(INPLANE{1}, rois{i}, scans, dt);
    GUI.controls.mvui(end+1) = mv.ui.fig;
end
       

return
