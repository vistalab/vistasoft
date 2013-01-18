function prefs = editPreferences;
% GUI to set mrVista preference variables.
%
%  prefs = editPreferences;
%
% Returns a prefs struct with each preference field and its current value. 
% This is the same struct that would be returned if you ran the command:
%	prefs = getpref('VISTA');
%
% NOTE ABOUT PREFERENCES: The preferences edited here are part of the 
% "preferences group" named 'VISTA'; they are only a subset of
% the preferences which may affect mrVista's behavior. For instance,
% the function mrmPreferences will edit a separate set of preferences under
% the 'mesh' preferences group, which determines behavior for dealing with
% surface meshes.
%
% TODO: sub-group the preferences according to related ideas, such as 'File
% Paths', 'Display', 'ROIs', etc. Build a more general GUI to allow the
% user to switch between these preference groups.
%
% ras, 07/2008.

%% get the current values of the preferences
prefs = getpref('VISTA');

%% build the dialog
% (we only build dialogs for certain items; some, for instance, are only
% relevant to mrVista2 GUI behavior.)
dlg(1).fieldName = 'verbose';
dlg(end).style = 'popup';
dlg(end).string = 'How much feedback when using mrVista?';
dlg(end).list = {'0 -- quiet, minimal feedback' ...
				 '1 -- moderate, most status updates, waitbars shown' ...
				 '2 -- verbose, highest level of feedback'};
dlg(end).value = prefsVerboseCheck + 1;

dlg(end+1).fieldName = 'fileFormat';
dlg(end).style = 'popup';
dlg(end).string = 'Save maps / anatomies in which format?';
dlg(end).list = {'default' 'nifti'};
dlg(end).value = prefsFormatCheck;

% this preference only needed for MATLAB <2007a
% (later versions always use JAVA)
v = ver('Matlab');
if str2num(v.Version) < 7.4
	dlg(end+1).fieldName = 'javaOn';
	dlg(end).style = 'checkbox';
	dlg(end).string = 'Use JAVA to render figures';
	if isfield(prefs, dlg(end).fieldName)
		dlg(end).value = prefs.(dlg(end).fieldName);
	else
		dlg(end).value = 0;
	end
end

dlg(end+1).fieldName = 'defaultAnatomyPath';
dlg(end).style = 'edit';
dlg(end).string = 'Default Anatomy Directory (if ''3DAnatomy'' link not present)';
dlg(end).value = prefsDefaultAnatPath;

dlg(end+1).fieldName = 'defaultROIPath';
dlg(end).style = 'edit';
dlg(end).string = 'Default Shared ROI Directory (relative to anatomy directory)';
if isfield(prefs, dlg(end).fieldName)
	dlg(end).value = prefs.(dlg(end).fieldName);
else
	dlg(end).value = 'ROIs';
end

xHairList = {'Regular Crosshairs' 'BrainVoyager style (gap near intersection)'};
dlg(end+1).fieldName = 'xHairMethod';
dlg(end).style = 'popup';
dlg(end).string = 'Method for rendering crosshairs (3-view)?';
dlg(end).list = xHairList;
if isfield(prefs, dlg(end).fieldName)
	dlg(end).value = prefs.(dlg(end).fieldName);
else
	dlg(end).value = 2;
end

dlg(end+1).fieldName = 'xHairColor';
dlg(end).style = 'number';
dlg(end).string = 'Crosshairs color (3-view)?';
if isfield(prefs, dlg(end).fieldName)
	dlg(end).value = prefs.(dlg(end).fieldName)(:)';
else
	dlg(end).value = [1 .5 .5]; % [.8 .8 .6];
end
dlg(end+1).fieldName = 'extendedGrayFields';
dlg(end).style = 'checkbox';
dlg(end).string = 'Gray views: Extended ''leftNodes''/''rightNodes'' fields';
if isfield(prefs, dlg(end).fieldName)
	dlg(end).value = prefs.(dlg(end).fieldName);
else
	dlg(end).value = 1;
end

dlg(end+1).fieldName = 'autoComputeG2VMap';
dlg(end).style = 'checkbox';
dlg(end).string = 'Auto-compute Gray->Vertex Map for Meshes';
if isfield(prefs, dlg(end).fieldName)
	dlg(end).value = prefs.(dlg(end).fieldName);
else
	dlg(end).value = 1;
end

dlg(end+1).fieldName = 'autoComputeV2GMap';
dlg(end).style = 'checkbox';
dlg(end).string = 'Auto-compute Vertex->Gray Map for Meshes';
if isfield(prefs, dlg(end).fieldName)
	dlg(end).value = prefs.(dlg(end).fieldName);
else
	dlg(end).value = 1;
end

dlg(end+1).fieldName = 'savePrefs';
dlg(end).style = 'checkbox';
dlg(end).string = 'Save GUI settings when you close a view window';
if isfield(prefs, dlg(end).fieldName)
	dlg(end).value = prefs.(dlg(end).fieldName);
else
	dlg(end).value = 1;
end

%% put up the dialog; get response
[resp ok] = generalDialog(dlg, 'Set mrVista Preferences', [.25 .25 .5 .5]);

if ~ok
	if prefs.verbose >= 1
		disp('Edit Preferences Canceled.')
		return
	end
end

% parse response for some fields (most should already be in the final
% format)
resp.verbose = cellfind(dlg(1).list, resp.verbose) - 1;
resp.xHairMethod = cellfind(xHairList, resp.xHairMethod);

%% set the preferences based on the dialog
for f = fieldnames(resp)'
	setpref( 'VISTA', f{1}, resp.(f{1}) );
end

% return the updated prefs
prefs = getpref('VISTA');

return


