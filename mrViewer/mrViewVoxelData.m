function mv = mrViewVoxelData(ui, roi);
%
% mv = mrViewTimeCourse(<ui>, <roi=selected ROI>);
%
% Plot a multi voxel UI for the selected ROI in a mrViewer UI.
%
% roi can be specified as an index into the mrViewer ROIs, a name
% of the ROI, or a loaded struct. ui defaults to the current viewer.
%
% ras, 07/06.
if notDefined('ui'), ui = mrViewGet; end
if notDefined('roi'),    roi = ui.rois(ui.settings.roi);    end

if ischar(roi)
    roi = ui.rois(cellfind({ui.rois.name}, roi));
    
elseif isnumeric(roi)
    roi = ui.rois(roi);
    
end

% this version is for mrVista 2, so we need a loaded mrSESSION.mat file,
% globals and all that (see sessionGUI_viewTimeCourse):
mrGlobals2;


% check if an event-related scan group is assigned. 
% If so, use that; otherwise use the GUI selected scans.
scans = GUI.settings.scan;
dt = GUI.settings.dataType;
if isfield(dataTYPES(dt).scanParams(scans(1)), 'scanGroup') & ...
        ~isempty(dataTYPES(dt).scanParams(scans(1)).scanGroup)
    [scans dt] = er_getScanGroup(INPLANE{1});
end
    
roi = roiParse(roi);
roi.viewType = 'Inplane'; % always in this space, even if it was 
                          % loaded from Volume/Gray

mv = multiVoxelUI(INPLANE{1}, roi, scans, dt);


if ~checkfields(GUI, 'controls', 'tcui')
    GUI.controls.tcui = [];
end
GUI.controls.tcui(end+1) = mv.ui.fig;


return


