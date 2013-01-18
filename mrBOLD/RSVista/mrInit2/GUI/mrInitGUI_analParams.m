function params = mrInitGUI_analParams(params);
% Assign analysis parameters for a new mrVista session (mrInit2).
%
% params = mrInitGUI_analParams(params);
%
% This GUI allows the user to assign GLM ("event-related") and
% coherence ("block") analysis parameters to scans, assign parfiles
% to scans, and group scans. It returns params for mrInit2 which include
% the updated parameters.
%
%
% ras, 07/2007.
if notDefined('params'),    params = mrInitDefaultParams;       end

%% GUI update function switch
% the callbacks will call this function with special calls to sub-functions
% in lieu of a params struct. Parse this:
if ischar(params)
	switch lower(params)
		case 'assignglmparams', mrInitGUI_assignGlmParams;
		case 'assigncoparams', mrInitGUI_assignCoParams;
		case 'assignparfiles', mrInitGUI_assignParfiles;
		case 'assignparfilepattern', mrInitGUI_assignParfilePattern;
		case 'groupscans', mrInitGUI_groupScans;			
		otherwise, error(sprintf('Invalid argument for %s', mfilename));
	end
	return
end


% --- the code below makes the GUI --- %
%%%%% params
fsz = 10;  % fontsize for controls
bgColor = [.9 .9 .9];  % background color for figure

%%%%% Create the main GUI figure
hFig = figure('Units', 'norm', 'Position', [.15 .3 .7 .35], ...
	'UserData', params, ...
	'Name', 'Assign Analysis Parameters', 'NumberTitle', 'off', ...
	'Color', bgColor, 'CloseRequestFcn', 'OK = 0; uiresume;');

%%%%% listboxes
%% scans listbox
annotations = {};
for i = 1:length(params.annotations)
	annotations{i} = sprintf('%i: %s', i, params.annotations{i});
end
hScans = uicontrol('Style', 'listbox', 'String', annotations, ...
	'Min', 0, 'Max', 2, 'Tag', 'ScanList', ... % multiple selection
	'Units', 'norm', 'Position', [.05 .2 .25 .7], ...	
	'BackgroundColor', 'w', 'ForegroundColor', 'k', 'FontSize', fsz);

% text label
uicontrol('Style', 'text', 'String', 'Scans', 'FontSize', fsz+2, ...
	'Units', 'norm', 'Position', [.05 .93 .25 .05], ...
	'HorizontalAlignment', 'center', 'BackgroundColor', bgColor);

%% parfiles listbox
for i = 1:length(annotations)  % nScans
	if (length(params.parfile) >= i) & (~isempty(params.parfile{i}))
		parfiles{i} = sprintf('%i: %s', i, params.parfile{i});
	else
		parfiles{i} = sprintf('%i: (none)', i);
	end
end
hParfiles = uicontrol('Style', 'listbox', 'String', parfiles, ...
	'Min', 0, 'Max', 2, 'Tag', 'ParfilesList', ... % multiple selection
	'Units', 'norm', 'Position', [.35 .2 .15 .7], 'Value', [], ...	
	'BackgroundColor', bgColor, 'ForegroundColor', 'k', 'FontSize', fsz);

% text label
uicontrol('Style', 'text', 'String', 'Parfiles', 'FontSize', fsz+2, ...
	'Units', 'norm', 'Position', [.35 .93 .15 .05],  ...
	'HorizontalAlignment', 'center', 'BackgroundColor', bgColor);

%% scan groups listbox
for i = 1:length(annotations)  % nScans
	scanGroups{i} = sprintf('%i: (none)', i);
end

for i = 1:length(params.scanGroups)
	for j = params.scanGroups{i}
		scanGroups{j} = sprintf('%i: %s', i, num2str(params.scanGroups{i}));
	end
end

hScanGroups = uicontrol('Style', 'listbox', 'String', scanGroups, ...
	'Min', 0, 'Max', 2, 'Tag', 'ScanGroupsList', ... % multiple selection
	'Units', 'norm', 'Position', [.55 .2 .15 .7], 'Value', [], ...	
	'BackgroundColor', bgColor, 'ForegroundColor', 'k', 'FontSize', fsz);

% text label
uicontrol('Style', 'text', 'String', 'Scan Groups', 'FontSize', fsz+2, ...
	'Units', 'norm', 'Position', [.55 .93 .12 .05], ...
	'HorizontalAlignment', 'center', 'BackgroundColor', bgColor);

%%%%% buttons
%% assign co params button
uicontrol('Style', 'pushbutton', 'String', 'Assign Coherence Params', ...
	'Units', 'norm', 'Position', [.75 .8 .2 .12], ...	
	'BackgroundColor', [.8 .8 .9], 'ForegroundColor', 'k', 'FontSize', fsz, ...
	'Callback', 'mrInitGUI_analParams(''assignCoParams''); ');

%% assign GLM params button
uicontrol('Style', 'pushbutton', 'String', 'Assign GLM Params', ...
	'Units', 'norm', 'Position', [.75 .65 .2 .12], ...	
	'BackgroundColor', [.8 .8 .9], 'ForegroundColor', 'k', 'FontSize', fsz, ...
	'Callback', 'mrInitGUI_analParams(''assignGlmParams''); ');

%% assign parfiles button
uicontrol('Style', 'pushbutton', 'String', 'Assign Parfiles', ...
	'Units', 'norm', 'Position', [.75 .5 .2 .12], ...	
	'UserData', hParfiles, ...
	'BackgroundColor', [.8 .8 .9], 'ForegroundColor', 'k', 'FontSize', fsz, ...
	'Callback', 'mrInitGUI_analParams(''assignParfiles''); ');

%% assign parfiles pattern button
uicontrol('Style', 'pushbutton', 'String', 'Assign Parfile Pattern', ...
	'Units', 'norm', 'Position', [.75 .35 .2 .12], ...	
	'UserData', hParfiles, ...
	'BackgroundColor', [.8 .8 .9], 'ForegroundColor', 'k', 'FontSize', fsz, ...
	'Callback', 'mrInitGUI_analParams(''assignParfilePattern''); ');

%% group scans button
uicontrol('Style', 'pushbutton', 'String', 'Group Scans', ...
	'Units', 'norm', 'Position', [.75 .2 .2 .12], ...	
	'UserData', hScanGroups, ...
	'BackgroundColor', [.8 .8 .9], 'ForegroundColor', 'k', 'FontSize', fsz, ...
	'Callback', 'mrInitGUI_analParams(''groupScans''); ');


%%%%%  GO / Cancel Buttons
uicontrol('Style', 'pushbutton', 'Units', 'norm', 'Position', [.1 .02 .2 .08], ...
		  'BackgroundColor', [.9 .8 .8], 'String', 'Cancel', ...
		  'Callback', 'OK = 0; uiresume;');

uicontrol('Style', 'pushbutton', 'Units', 'norm', 'Position', [.5 .02 .2 .08], ...
		  'BackgroundColor', [.4 .8 .5], 'String', 'OK', ...
		  'Callback', 'OK = 1; uiresume;');


%%%%% get the params: do a uiwait/uiresume
% (uiresume is in the callbacks for this GUI)
uiwait;


%% we uiresumed: get the updated values from the figure
OK = evalin('base', 'OK');
evalin('base', 'clear OK'); % clear from base workspace
if OK==1	
	% get modified params
	params = get(gcf, 'UserData');
end

delete(hFig);



return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function mrInitGUI_assignCoParams;
% put up a dialog to set the coherence params for the selected scans,
% then modify the stored coParams field to match the edited params.
params = get(gcf, 'UserData');

hScans = findobj('Parent', gcf, 'Tag', 'ScanList');
selScans = get(hScans, 'Value');

% get initial values: take from the first selected scan
% if it's assigned in params, use that; else use defaults
s = selScans(1);
if (length(params.coParams) >= s)  &  (~isempty(params.coParams{s}))
	coParams = params.coParams{s};
else
	coParams = coParamsDefault;
end

% have user edit the values
[coParams ok] = coParamsEdit(coParams);
if ~ok, return; end

% update the params field
for s = selScans
	params.coParams{s} = coParams;
end

set(gcf, 'UserData', params);
return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function mrInitGUI_assignGlmParams;
% put up a dialog to set the GLM analysis params for the selected scans,
% then modify the stored glmParams field to match the edited params.
params = get(gcf, 'UserData');

hScans = findobj('Parent', gcf, 'Tag', 'ScanList');
selScans = get(hScans, 'Value');

% get initial values: take from the first selected scan
% if it's assigned in params, use that; else use defaults
s = selScans(1);
if (length(params.coParams) >= s)  &  (~isempty(params.coParams{s}))
	glmParams = params.glmParams{s};
else
	glmParams = er_defaultParams;
end

% have user edit the values
[glmParams ok] = er_editParams(glmParams);
if ~ok, return; end

% update the params field
for s = selScans
	params.glmParams{s} = glmParams;
end

set(gcf, 'UserData', params);
return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function mrInitGUI_assignParfiles;
% prompt the user to select parfiles to assign to the selected scans,
% and update the params and GUI accordingly.
params = get(gcf, 'UserData');

hScans = findobj('Parent', gcf, 'Tag', 'ScanList');
selScans = get(hScans, 'Value');

% first, we need to make sure we have a parfiles directory:
% this is either stim/parfiles or Stimuli/parfiles in the session dir:
parDir = fullfile(params.sessionDir, 'Stimuli', 'parfiles');
if ~exist(parDir, 'dir')
	if exist( fullfile(params.sessionDir, 'stim', 'parfiles'), 'dir' )
		parDir = fullfile(params.sessionDir, 'stim', 'parfiles');
	end
end

if ~exist(parDir, 'dir')
	myWarnDlg(['You don''t have a Stimuli/parfiles directory ' ...
			   'in your session directory. Parfiles should be kept there.']);
   return
end

parList = dir( fullfile(parDir, '*.par') );
parList = {parList.name};

% also add an option to remove the assignment of a parfile:
parList = [{'(none)'} parList];

% put up the dialog
ttl = sprintf('Select parfiles to assign to scans: %s', num2str(selScans));
	
[sel, ok] = listdlg('PromptString', ttl, 'ListSize', [400 600], ...
					'ListString', parList, 'InitialValue', 1, ...
					'OKString', 'OK');
if ~ok  return;  end

% ensure the selected parfiles match the number of selected scans.
% The strategy here is simple: if sel is shorter than selScans, 
% all scans in between get assigned the last selected parfile. 
% This way, you can assign one parfile to many scans easily.
if length(sel) < length(selScans)
	nExtra = length(selScans) - length(sel);
	sel = [sel repmat(sel(end), [1 nExtra])];
end

% update the parfiles listbox
hParfiles = findobj('Parent', gcf, 'Tag', 'ParfilesList');
str = get(hParfiles, 'String');
for s = 1:length(selScans)
	str{selScans(s)} = sprintf('%i: %s', s, parList{sel(s)});
end
set(hParfiles, 'String', str);

% update the params field
for s = 1:length(selScans)
	if sel(s)==1	% selected 'none', no parfile to this scan
		params.parfile{selScans(s)} = '';
	else
		params.parfile{selScans(s)} = parList{sel(s)};
	end
end
set(gcf, 'UserData', params);

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function mrInitGUI_assignParfilePattern;
% a separate dialog providing a more flexible way to assign parfiles
% to scans: if the parfiles for several scans have a common pattern
% in their names -- e.g., 'run1.par' through 'run5.par' -- this dialog
% lets the user specify the pattern, and the sequence of numbers which
% correspond to the selected scans.
%
% Note that the sequence of numbers need not run from 1 to N, nor
% be linear increasing. For instance, suppose I ran my scripts in a
% counterbalanced order, going forwards (1-10) in one session, and 
% backwards (10-1) in another session. And suppose a scanning glitch 
% caused run 1 to precede run 2. I might assign it thusly:
%
% pattern: run%i.par
% runs:  [10:-1:3 1 2]
%
% Since this code uses sprintf formatting, the user needs to put the
% symbol '%i' where the number should go.
%
% The code then updates the params and the GUI with the new parfiles.
params = get(gcf, 'UserData');

hScans = findobj('Parent', gcf, 'Tag', 'ScanList');
selScans = get(hScans, 'Value');

% build the dialog
dlg(1).fieldName = 'pattern';
dlg(1).style	 = 'edit';
dlg(1).string	 = ['Parfile pattern: insert a %i where the run number ' ...
					'should go. (E.g. ''run%i.par'') '];
dlg(1).value	 = '%i.par';

dlg(2).fieldName = 'runVals';
dlg(2).style	 = 'edit';
dlg(2).string	 = ['Run values (will be pasted in %i position); ' ...
					'E.g. ''1:8'', ''8:-1:1'', ''[1 3 5:9]'' '];
dlg(2).value	 = '';				

% put up the dialog and get a response
resp = generalDialog(dlg, 'Assign Parfile Pattern', 'center');

% generate the new parfile list
runVals = str2num( resp.runVals );
for s = runVals
	parList{s} = sprintf( resp.pattern, s );
end

% update the parfiles listbox
hParfiles = findobj('Parent', gcf, 'Tag', 'ParfilesList');
str = get(hParfiles, 'String');
for s = selScans
	str{s} = sprintf('%i: %s', s, parList{s});
end
set(hParfiles, 'String', str);


% update the params field
for s = 1:length(selScans)
	params.parfile{selScans(s)} = parList{s};
end
set(gcf, 'UserData', params);

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function mrInitGUI_groupScans;
% group the selected scans in the scans list. This modified the
% params.scanGroupField, and updates the scan group listbox to 
% reflect that change.
params = get(gcf, 'UserData');

hScans = findobj('Parent', gcf, 'Tag', 'ScanList');
selScans = get(hScans, 'Value');

params.scanGroups{end+1} = selScans;

% update the scan groups listbox
hScanGroup = findobj('Parent', gcf, 'Tag', 'ScanGroupsList');
str = get(hScanGroup, 'String');
for s = selScans
	str{s} = sprintf('%i: [%s]', s, num2str(selScans));
end
set(hScanGroup, 'String', str);

% set updated params
set(gcf, 'UserData', params);
return

