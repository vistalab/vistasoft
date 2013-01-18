function params = er_editParamsScanGroup(view);
%
% params = er_editParamsScanGroup(view);
%
% Edit the event-related parameters for a scan group.
%
%
% ras, 10/26/2007 -- replacement for a fairly long callback in the
% eventMenu. This code adds a check for the GLMs data type, which was
% missing in the callback; and makes things easier to edit.
if notDefined('view'),	view = getCurView;		end

% get the scan group for the selected scan in the view:
[scans dt] = er_getScanGroup(view);

% get the data type name corresponding to the scan group's data type
global dataTYPES
dtName = dataTYPES(dt).name;

% get the event-related parameters for this group
% (use 1st scan only)
params = er_getParams(view, scans(1), dt);

% special case:
% check if we're in the 'GLMs' data type;
% if so, warn the user that this option may not make sense
if isequal( viewGet(view, 'dataTypeName'), 'GLMs' )
	warnMsg = ['The current data type is "GLMs". ' ...
			   'The event-related parameters for this data type ' ...
			   'are not to be modified, and serve as a log of ' ...
			   'the parameters used for the analysis. ' ...
			   'However, you may edit the parameters for the ' ...
			   'original data and data type, which will ' ...
			   'affect future analyses on that data.' ...
			   'What would you like to do?'];
	
	btn1 = sprintf('Edit %s %s params', dtName, num2str(scans));
	btn2 = 'Dump Saved GLM params to command line';
	
	resp = questdlg(warnMsg, 'Warning', btn1, btn2, 'Cancel', btn1);
	
	if ~isequal(resp, btn1)
		if isequal(resp, btn2)
			% dump the stored GLM params to the command line
			params = er_getParams(view, view.curScan, view.curDataType);
			assignin('base', 'GLMparams', params);
			disp(['Assigned stored GLM parameters to the variable ' ...
				  '"GLMparams" in the workspace.']);
			evalin('base', 'GLMparams');
		end
		
		return
	end
end

% edit the parameters (puts up dialog for user)
params = er_editParams(params, dtName);

% set in the scan group
er_setParams(view, params, scans, dt);

return

