function [active, control, names] = contrastBatchGUI(view, active, control, names);
% Graphical user interface for running computing multiple contrast
% maps using computeContrastMap2.
%
% USAGE:
% [active, control, names] = contrastBatchGUI(view, [active], [control], [names]);
%
% This GUI will have edit fields where the user can type in sets of
% active and control conditions for a batch of contrasts, as well as names
% for each contrast. The optional inputs 'active', 'control', and 'names'
% can be used to provide initial values for the fields, which the users can
% edit. Each of these is a cell array, whose length corresponds to the
% number of contrasts to compute. Each entry in active and control should
% be a numeric index of active (+) and control (-) conditions,
% respectively, while each entry in names should be a string. 
%
% (Note that for contrasts, entering 0 (null condition) as an active or
% control condition will cause the contrast to test whether the beta values
% are nonzero (positive or negative), while entering 0 plus other nonzero
% conditions will compare it only to the nonzero conditions, ignoring the
% 0.)
%
% (Also note that, right now, this is for batch computation of maps with
% units -log(p); options to vary the units may be added if needed.)
%
% Returns the final values of each of the edit fields, and calls
% computeContrastMap2 iteratively for each contrast.
%
%
% ras, 08/31/2007.
if notDefined('view'),		view = getCurView;		end
if notDefined('active'),	active = {[]};			end
if notDefined('control'),	control = {[]};			end
if notDefined('names'),		names = {''};			end

%% make the figure
stim = er_concatParfiles(view);
h = makeBatchGUI(stim, active, control, names);

%% wait for user response (uiresume)
uiwait;

resp = get(h, 'UserData');
delete(h);

if resp.ok==0  % user canceled or closed the figure
	return
end

active = resp.active;
control = resp.control;
names = resp.names;

% size check on the fields: should have the same # entries
n1 = length(active);
n2 = length(control);
n3 = length(names);

if n1 ~= n2,  error('Need the same number of active and control entries.'); end
if n1 ~= n3,  error('Need the same number of active entries and names.');	end
if n2 ~= n3,  error('Need the same number of control entries and names.');	end

%% compute the contrasts
for n = 1:n1
	computeContrastMap2(view, active{n}, control{n}, names{n});
end

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function h = makeBatchGUI(stim, active, control, names);
% Create the interface window for specifying the batch contrasts.

%% create a response structure which keeps track of the user inputs
resp.ok = 0;  % ok flag; gets set to 1 only if user presses 'ok' button
resp.active = active;
resp.control = control;
resp.names = names;

bgColor = [.9 .9 .9];  % background color for non-active controls
fsz = 9;				% font size for edit fields

%% create the figure
h = figure('Color', bgColor, 'Name', 'Contrast Map Batch GUI', ...
			'NumberTitle', 'off', 'Units', 'normalized', ...
			'Position', [.15 .2 .7 .6], 'MenuBar', 'none', ...
			'UserData', resp, 'CloseRequestFcn', 'uiresume');
addFigMenuToggle(h);


%% list showing what the names are for each condition
for i = 1:length(stim.condNames)
	str{i} = sprintf('%i. %s', stim.condNums(i), stim.condNames{i});
end

% main list
uicontrol('Style', 'listbox', 'Units', 'norm', 'Position', [.05 .2 .15 .6], ...
		  'Min', 1, 'Max', 10, 'String', str, ...
		  'BackgroundColor', bgColor, 'ForegroundColor', 'k', ...
		  'FontSize', fsz, 'HorizontalAlignment', 'left');

% label
uicontrol('Style', 'text', 'Units', 'norm', 'Position', [.05 .82 .2 .06], ...
		  'String', 'Condition List', 'ForegroundColor', 'k', ...
		  'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
		  'BackgroundColor', bgColor, 'FontSize', fsz+3);
		
	  
%% edit field for active conditions
for i = 1:length(active) % convert to string for edit field
	active{i} = num2str(active{i});
end

% callback
cb = ['resp = get(gcf, ''UserData''); ' ...
	  'resp.active = get(gcbo, ''String''); ' ...
	  'for i = 1:length(resp.active), ' ...
	  ' resp.active{i} = str2num(resp.active{i}); ' ...
	  'end; ' ...
	  'set(gcf, ''UserData'', resp); ']; 

% main list
uicontrol('Style', 'edit', 'Units', 'norm', 'Position', [.25 .2 .15 .6], ...
		  'Min', 1, 'Max', 10, 'String', active, ...
		  'BackgroundColor', 'w', 'ForegroundColor', 'k', ...
		  'FontSize', fsz, 'HorizontalAlignment', 'left', ...
		  'Callback', cb);

% label
uicontrol('Style', 'text', 'Units', 'norm', 'Position', [.25 .82 .2 .12], ...
		  'String', 'Active Conditions', ...
		  'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
		  'BackgroundColor', bgColor, 'ForegroundColor', 'k', 'FontSize', fsz+3);	  

	  
%% edit field for control conditions
for i = 1:length(control)  % convert to string for edit field
	control{i} = num2str(control{i});
end

% callback
cb = ['resp = get(gcf, ''UserData''); ' ...
	  'resp.control = get(gcbo, ''String''); ' ...
	  'for i = 1:length(resp.control), ' ...
	  ' resp.control{i} = str2num(resp.control{i}); ' ...
	  'end; ' ...
	  'set(gcf, ''UserData'', resp); ']; 

% main list
uicontrol('Style', 'edit', 'Units', 'norm', 'Position', [.5 .2 .15 .6], ...
		  'Min', 1, 'Max', 10, 'String', control, ...
		  'BackgroundColor', 'w', 'ForegroundColor', 'k', ...
		  'FontSize', fsz, 'HorizontalAlignment', 'left', ...
		  'Callback', cb);

% label
uicontrol('Style', 'text', 'Units', 'norm', 'Position', [.5 .82 .2 .12], ...
		  'String', 'Control Conditions', ...
		  'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
		  'BackgroundColor', bgColor, 'ForegroundColor', 'k', 'FontSize', fsz+3);	  
	  
	  
%% edit field for contrast names
% callback
cb = ['resp = get(gcf, ''UserData''); ' ...
	  'resp.names = get(gcbo, ''String''); ' ...
	  'set(gcf, ''UserData'', resp); ']; 

% main list
uicontrol('Style', 'edit', 'Units', 'norm', 'Position', [.75 .2 .15 .6], ...
		  'Min', 1, 'Max', 10, 'String', names, ...
		  'BackgroundColor', 'w', 'ForegroundColor', 'k', ...
		  'FontSize', fsz, 'HorizontalAlignment', 'left', ...
		  'Callback', cb);

% label
uicontrol('Style', 'text', 'Units', 'norm', 'Position', [.75 .82 .2 .12], ...
		  'String', 'Contrast Names', ...
		  'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
		  'BackgroundColor', bgColor, 'ForegroundColor', 'k', 'FontSize', fsz+3);
	  
%% OK, Cancel buttons
uicontrol('Style', 'pushbutton', 'Units', 'norm', 'Position', [.1 .02 .2 .08], ...
		  'BackgroundColor', [.9 .8 .8], 'String', 'Cancel', ...
		  'Callback', 'uiresume');

cb = ['resp = get(gcf, ''UserData''); ' ...
	  'resp.ok = 1; ' ...
	  'set(gcf, ''UserData'', resp); ' ...
	  'uiresume'];	  
	 
uicontrol('Style', 'pushbutton', 'Units', 'norm', 'Position', [.5 .02 .2 .08], ...
		  'BackgroundColor', [.4 .8 .5], 'String', 'OK', ...
		  'Callback', cb);
	  
return
