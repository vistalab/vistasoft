function params = mrInitGUI_skipFrames(params, varargin);
% Scan Description dialog for mrInitGUI.
%
% params = mrInitGUI_skipFrames(params);
%
% This code allows you to edit the params.keepFrames field of mrInit2 params. 
% (See mrInitDefaultParams for more details). The GUI will have one row of 
% uicontrols for each functional scan in the session. Separate columns
% specify which frames to skip before the first frame to keep in the time
% series, and how many remaining frames to keep.
%
%
% ras, 05/2007
if notDefined('params'),    params = mrInitDefaultParams;       end


%%%%% params
fsz = 10;  % fontsize for controls
nScans = length(params.functionals);
height = 8 + 2*nScans;  % height in characters of GUI figure
width = 80;		 % width in characters of GUI figure


%%%%%%%%%%%%%%%%%%%%%
% create the figure %
%%%%%%%%%%%%%%%%%%%%%
hFig = figure('Units', 'char', 'Position', [10 5 width height], ...
	'Name', 'mrVista Session Description', 'NumberTitle', 'off', ...
	'UserData', params, ...
	'Color', [.9 .9 .9], 'CloseRequestFcn', 'OK = 0; uiresume;');
centerfig(hFig, 0);  % center on screen
	
%% add a row of text labels for the headings
% scan #
uicontrol('Style', 'text', 'Units', 'char', 'Position', [2 height-4 8 3], ...
		  'FontWeight', 'bold','HorizontalAlignment', 'left', ...
		  'String', 'Scan', 'FontSize', fsz, ...
		  'BackgroundColor', [.9 .9 .9]);
	  
uicontrol('Style', 'text', 'Units', 'char', 'Position', [14 height-4 20 3], ...
		  'FontWeight', 'bold','HorizontalAlignment', 'left', ...
		  'String', 'Input File', 'FontSize', fsz, ...
		  'BackgroundColor', [.9 .9 .9]);	  
	  
% # skip frames  
uicontrol('Style', 'text', 'Units', 'char', 'Position', [40 height-4 20 3], ...
		  'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
		  'String', 'Skip', 'FontSize', fsz, ...
		  'BackgroundColor', [.9 .9 .9]);
	  
% # keep frames
uicontrol('Style', 'text', 'Units', 'char', 'Position', [55 height-4 20 3], ...
		  'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
		  'String', 'Keep (after skipped frames)', 'FontSize', fsz, ...
		  'BackgroundColor', [.9 .9 .9]);

%% add each row of controls
for scan = 1:nScans
	[hSkip(scan) hKeep(scan)] = skipFramesRow(params, scan, fsz, height-4-2*scan);
end


%% GO / Cancel buttons
uicontrol('Style', 'pushbutton', 'Units', 'char', 'Position', [2 1 20 2], ...
		  'BackgroundColor', [.9 .8 .8], 'String', 'Cancel', ...
		  'Callback', 'OK = 0; uiresume;');

uicontrol('Style', 'pushbutton', 'Units', 'char', 'Position', [width-30 1 20 2], ...
		  'BackgroundColor', [.4 .8 .5], 'String', 'OK', ...
		  'Callback', 'OK = 1; uiresume;');

% allow resizing of the figure
set( findobj('Parent', hFig, 'Type', 'uicontrol'), 'Units', 'norm');  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% uiwait / uiresume loop; parse response %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uiwait
OK = evalin('base', 'OK');
evalin('base', 'clear OK'); % clear from base workspace
if OK==1	
	% if 'Cancel' button pressed or figure closed: don't modify params;
	% if we got here: things should be ok, so let's clear the previous
	% keepFrames information and read the new info off the GUI
	params.keepFrames = [];
	
	for scan = 1:nScans
		nSkip = str2num( get(hSkip(scan), 'String') );
		nKeep = get(hKeep(scan), 'String');
		if isequal(lower(nKeep), 'all')
			nKeep = -1; % flag to keep all remaining frames
		else
			nKeep = str2num(nKeep);
		end
		
		if isempty(nSkip) | isempty(nKeep)
			warning('Empty parameter provided -- not setting parameters')
			params.keepFrames = [];
			return
		end
		
		params.keepFrames(scan,:) = [nSkip nKeep];
	end
end

%% close the figure
delete(hFig);

return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function [h1 h2] = skipFramesRow(params, scan, fsz, y);
% Create a row of uicontrols for editing functional annotations,
% returning a handle to the relevant edit field.

%% scan #
uicontrol('Style', 'text', 'Units', 'char', 'Position', [2 y 7 2], ...
		  'String', num2str(scan), 'FontSize', fsz, ...
		  'BackgroundColor', [.9 .9 .9]);
	  
%% input file name  
[p f ext] = fileparts(params.functionals{scan});
uicontrol('Style', 'text', 'Units', 'char', 'Position', [10 y 25 2], ...
		  'String', [f ext], 'FontSize', fsz, ...
		  'BackgroundColor', [.9 .9 .9]);
	  
%% nSkip field
% tag for finding this edit field (in the '_copy' callback):
tag = sprintf('mrInitGUI_skip_scan%i', i);

% make the edit field
h1 = uicontrol('Style', 'edit', 'Units', 'char', 'Position', [40 y 6 2], ...
		  'String', '0', 'FontSize', fsz, 'Tag', tag, ...
		  'BackgroundColor', 'w');
	  
%% nKeep field
% tag for finding this edit field (in the '_copy' callback):
tag = sprintf('mrInitGUI_keep_scan%i', i);

% make the edit field
h2 = uicontrol('Style', 'edit', 'Units', 'char', 'Position', [55 y 6 2], ...
		  'String', 'all', 'FontSize', fsz, 'Tag', tag, ...
		  'BackgroundColor', 'w');
	  
	  
return
