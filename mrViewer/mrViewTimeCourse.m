function tc = mrViewTimeCourse(ui, roi)
% Plot a time course UI for the selected ROI in a mrViewer UI.
%
%  tc = mrViewTimeCourse(<ui>, <roi=selected ROI>);
%
% roi can be specified as an index into the mrViewer ROIs, a name
% of the ROI, or a loaded struct. ui defaults to the current viewer.
%
% ras, 07/06.

if notDefined('ui'), ui = mrViewGet; end
if ishandle(ui), ui = get(ui, 'UserData'); end
if notDefined('roi')
    if ui.settings.roi > 0, roi = ui.rois(ui.settings.roi);    
    else warndlg('Choose an ROI prior to plotting'); return;
    end
end

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
scans = GUI.settings.scan; %#ok<NODEF>
dt = GUI.settings.dataType;
if isfield(dataTYPES(dt).scanParams(scans(1)), 'scanGroup') && ...
        ~isempty(dataTYPES(dt).scanParams(scans(1)).scanGroup)
    [scans dt] = er_getScanGroup(INPLANE{1}); %#ok<USENS>
end
    
roi = roiParse(roi);
roi.viewType = 'Inplane'; % always in this space, even if it was 
                          % loaded from Volume/Gray
if ~isequal(guiGet('anatomyName'), 'Inplane')
    roi = roiCheckCoords(roi, guiGet('inplane'));
end

% special case: for GLMs data type, the time series will be
% in a different d.t. We don't need to ask the user to confirm 
% in this case, it should be understood.
if isequal(dataTYPES(dt).name, 'GLMs')
	queryFlag = 1;
else
	queryFlag = 0;
end

tc = timeCourseUI(INPLANE{1}, roi, scans, dt, queryFlag);

if ~checkfields(GUI, 'controls', 'tcui')
    GUI.controls.tcui = [];
end
GUI.controls.tcui(end+1) = tc.ui.fig;

return


